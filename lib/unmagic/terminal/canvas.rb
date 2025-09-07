# frozen_string_literal: true

require "set"
require "unmagic/support/rate"
require "unmagic/support/percentage"
require_relative "canvas/region"
require_relative "canvas/region_collection"
require_relative "canvas/renderer"

module Unmagic
  module Terminal
    # Main canvas that manages regions and coordinates terminal updates through a single UI thread.
    # All terminal I/O is handled by one thread to prevent corruption from concurrent writes.
    #
    # Example:
    #
    #   canvas = Unmagic::Terminal::Canvas.new
    #   canvas.define_region(:status, x: 0, y: 0, width: 80, height: 3, bg: :blue)
    #   canvas.define_region(:logs, x: 0, y: 4, width: 80, height: 20)
    #
    #   canvas.regions[:status] = "Ready"
    #   canvas.regions[:logs] << "Starting...\n"
    class Canvas
      class Error < StandardError; end

      attr_reader :regions

      def target_fps
        @fps
      end

      def actual_fps
        @rate_monitor.current_rate
      end

      # Get performance statistics
      def performance_stats
        efficiency = actual_fps.positive? ? Unmagic::Support::Percentage.new(actual_fps, @fps) : Unmagic::Support::Percentage.new(0)
        {
          target_fps: @fps,
          actual_fps: actual_fps,
          frame_efficiency: efficiency.value
        }
      end

      def initialize(output: $stdout, fps: 24)
        @output = output
        @fps = fps
        @frame_duration = 1.0 / @fps
        @regions_map = {}
        @message_queue = Thread::Queue.new
        @regions = RegionCollection.new(self)
        @renderer = Renderer.new(output)
        @running = false
        @ui_thread = nil
        @mutex = Mutex.new

        # Frame rate monitoring
        @rate_monitor = Unmagic::Support::Rate.new(window: 1.0)

        # Save initial cursor position as canvas origin
        @origin_saved = false
        save_cursor_position
      end

      # Define a new region with a name and properties
      def define_region(name, x:, y:, width:, height:, **options)
        @mutex.synchronize do
          raise ArgumentError, "Region #{name} already exists" if @regions_map[name]

          region = Region.new(
            id: name,
            x: x,
            y: y,
            width: width,
            height: height,
            **options
          )

          @regions_map[name] = region
        end

        # Initial render of empty region (only if UI thread is running)
        send_message(:render, name, nil) if @running

        self
      end

      # Send a message to the UI thread (internal use)
      def send_message(type, region_id, content = nil)
        @message_queue << { type: type, region_id: region_id, content: content }
      end

      # Get a region by name (internal use)
      def get_region(name)
        @mutex.synchronize { @regions_map[name] }
      end

      # Check if a region exists
      def has_region?(name)
        @mutex.synchronize { @regions_map.key?(name) }
      end

      # Stop the canvas and restore terminal
      def stop
        @running = false
        @message_queue << { type: :stop }
        @ui_thread&.join(1) # Wait up to 1 second
        restore_cursor_position
      end

      # Clear all regions
      def clear
        @mutex.synchronize do
          @regions_map.each_key do |name|
            send_message(:clear, name)
          end
        end
      end

      # Start the canvas UI thread
      # async: false (default) - Block main thread until stopped
      # async: true - Run in background thread, return immediately
      def start(async: false)
        raise Error, "Canvas is already running" if @ui_thread&.alive?

        @running = true

        # Process all pending messages and do initial synchronized render
        # This makes all regions appear simultaneously
        perform_initial_render

        start_ui_thread

        if async
          # Return immediately, UI thread runs in background
          @ui_thread
        else
          # Block main thread until interrupted
          begin
            @ui_thread.join
          rescue Interrupt
            stop
          end
        end
      end

      private

      def perform_initial_render
        # Process all pending messages to update region data
        dirty_regions = Set.new

        until @message_queue.empty?
          message = begin
            @message_queue.pop(non_block: true)
          rescue StandardError
            break
          end
          process_message_to_region(message)
          dirty_regions << message[:region_id]
        end

        # Add all existing regions to dirty set for initial render
        @mutex.synchronize do
          @regions_map.each_key { |region_id| dirty_regions << region_id }
        end

        # Render all regions simultaneously with synchronized updates
        render_frame_synchronized(dirty_regions) unless dirty_regions.empty?
      end

      def save_cursor_position
        return if @origin_saved

        @output.print "\e[s" # Save cursor position
        @output.flush
        @origin_saved = true
      end

      def restore_cursor_position
        return unless @origin_saved

        @output.print "\e[u" # Restore cursor position
        @output.flush
        @origin_saved = false
      end

      def start_ui_thread
        @ui_thread = Thread.new do
          while @running
            begin
              # Block here when idle - preserves sleep behavior when no messages
              first_message = @message_queue.pop
              break if first_message[:type] == :stop

              # Start frame processing - we have at least one message
              frame_start = Time.now
              dirty_regions = Set.new

              # Process the first message
              process_message_to_region(first_message)
              dirty_regions << first_message[:region_id]

              # Collect ALL additional messages (no time limit)
              loop do
                message = begin
                  @message_queue.pop(non_block: true)
                rescue StandardError
                  break
                end
                break if message[:type] == :stop

                process_message_to_region(message)
                dirty_regions << message[:region_id]
              end

              # Render all dirty regions with synchronized updates
              render_frame_synchronized(dirty_regions) unless dirty_regions.empty?

              # Record frame for performance measurement
              @rate_monitor.record_event

              # Sleep for remaining frame time to maintain consistent FPS
              frame_time = Time.now - frame_start
              remaining_time = [ @frame_duration - frame_time, 0 ].max
              sleep(remaining_time) if remaining_time.positive?
            rescue StandardError => e
              # Log error but keep thread running
              warn "Canvas UI thread error: #{e.message}"
            end
          end
        end
      end

      # Process message to update region data only (no rendering)
      def process_message_to_region(message)
        region = get_region(message[:region_id])
        return unless region

        case message[:type]
        when :update
          region.content = message[:content]
        when :append
          region.append_content(message[:content])
        when :clear
          region.clear
        when :render
          # For render messages, region is already up to date
        end
      end

      # Render all dirty regions with synchronized terminal updates
      def render_frame_synchronized(dirty_regions)
        # Begin synchronized update - terminal buffers all output
        @output.print "\033[?2026h"

        # Render all dirty regions without individual flushes
        dirty_regions.each do |region_id|
          region = get_region(region_id)
          @renderer.render_region_without_flush(region) if region
        end

        # End synchronized update and flush - display everything atomically
        @output.print "\033[?2026l"
        @output.flush
      end

      # Legacy method for backward compatibility during transition
      def process_message(message)
        region = get_region(message[:region_id])
        return unless region

        case message[:type]
        when :update
          region.content = message[:content]
          @renderer.render_region(region)
        when :append
          region.append_content(message[:content])
          @renderer.render_region(region)
        when :clear
          region.clear
          @renderer.render_region(region)
        when :render
          @renderer.render_region(region)
        end
      end
    end
  end
end
