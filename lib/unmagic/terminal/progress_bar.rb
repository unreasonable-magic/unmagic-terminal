# frozen_string_literal: true

require "unmagic/support/rate"
require "unmagic/support/percentage"

module Unmagic
  module Terminal
    # Progress bar with time estimation using Rate
    #
    # Example:
    #
    #   progress_bar = ProgressBar.new(total: 1000, width: 50)
    #   (1..1000).each do |i|
    #     progress_bar.update(i)
    #     puts progress_bar.render
    #     sleep(0.01)
    #   end
    class ProgressBar
      FILLED_CHAR = "█"
      EMPTY_CHAR = "░"

      attr_reader :current, :total, :width, :description

      def initialize(total: 1, current: 0, width: 40, show_time: true, description: nil)
        @total = total
        @current = current
        @width = width
        @show_time = show_time
        @description = description
        @rate_monitor = Unmagic::Support::Rate.new(window: 5.0) # 5 second window for smoother estimates
        @last_update = nil
      end

      # Update the progress and record the event for rate monitoring
      def update(current)
        @current = [ current, @total ].min

        # Record event for rate monitoring only if progress actually increased
        return unless @last_update.nil? || current > @last_update

        @rate_monitor.record_event
        @last_update = current
      end

      # Increment progress by one and record the event
      def increment
        update(@current + 1)
      end

      # Render the progress bar as a string
      def render
        parts = []
        parts << render_bar
        parts << render_percentage
        parts << render_time_estimate if @show_time
        parts.join(" ")
      end

      # Get the completion percentage
      def percentage
        Unmagic::Support::Percentage.new(@current, @total)
      end

      # Check if the progress is complete
      def complete?
        @current >= @total
      end

      # Reset the progress bar
      def reset
        @current = 0
        @rate_monitor.reset
        @last_update = nil
      end

      private

      def render_bar
        return EMPTY_CHAR * @width if @total <= 0

        filled_width = (@current.to_f / @total * @width).round
        empty_width = @width - filled_width

        filled_part = filled_width.positive? ? FILLED_CHAR * filled_width : ""
        empty_part = empty_width.positive? ? EMPTY_CHAR * empty_width : ""

        filled_part + empty_part
      end

      def render_percentage
        percentage.to_s
      end

      def render_time_estimate
        return "ETA: unknown" if complete?

        remaining_time = @rate_monitor.estimate_time_remaining(
          total_items: @total,
          completed_items: @current
        )

        if remaining_time
          formatted_time = Unmagic::Support::Rate.format_time_remaining(remaining_time)
          "ETA: #{formatted_time}"
        else
          "ETA: calculating..."
        end
      end
    end
  end
end
