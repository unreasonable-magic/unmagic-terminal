#!/usr/bin/env ruby
# frozen_string_literal: true

# Canvas-based Progress Bar Demo using Unmagic::Terminal::Canvas
$LOAD_PATH.unshift(File.expand_path('../../unmagic-color/lib', __dir__))
$LOAD_PATH.unshift(File.expand_path('../../unmagic-support/lib', __dir__))
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'unmagic-terminal'
require 'unmagic/terminal/canvas'
require 'unmagic/support/percentage'

# Progress bar rendering class that works with canvas regions
class CanvasProgressBar
  FILLED_CHAR = '█'
  EMPTY_CHAR = '░'

  def initialize(width: 40)
    @width = width
    @segments = []
  end

  def add_segment(name, max: 100, value: 0, color: :blue, label: nil)
    @segments << {
      name: name,
      max: max,
      value: value,
      color: color,
      label: label || name.to_s.capitalize
    }
  end

  def update_segment(name, value)
    segment = @segments.find { |s| s[:name] == name }
    return unless segment

    segment[:value] = [ value, segment[:max] ].min
  end

  def render
    return render_empty if @segments.empty?

    lines = []
    lines << render_bar
    lines << render_details if @segments.size > 1 || @segments.any? { |s| s[:label] }
    lines.compact.join("\n")
  end

  private

  def render_empty
    "#{EMPTY_CHAR * @width} 0.0%"
  end

  def render_bar
    total_max = @segments.sum { |s| s[:max] }
    return render_empty if total_max <= 0

    bar_parts = []

    @segments.each do |segment|
      segment_width = (segment[:max].to_f / total_max * @width).round
      filled_width = (segment[:value].to_f / segment[:max] * segment_width).round

      # Add filled portion (no ANSI colors for canvas compatibility)
      bar_parts << FILLED_CHAR * filled_width if filled_width.positive?

      # Add empty portion
      empty_width = segment_width - filled_width
      bar_parts << EMPTY_CHAR * empty_width if empty_width.positive?
    end

    # Calculate total progress
    total_progress_ratio = @segments.sum { |s| (s[:value].to_f / s[:max]) * (s[:max].to_f / total_max) }
    total_progress = Unmagic::Support::Percentage.new(total_progress_ratio * 100)

    "#{bar_parts.join} #{total_progress}"
  end

  def render_details
    details = @segments.map do |segment|
      percentage = Unmagic::Support::Percentage.new(segment[:value], segment[:max])
      # No ANSI colors for canvas compatibility
      "#{segment[:label]}: #{percentage}"
    end

    details.join('  ')
  end
end

# Clear screen and hide cursor
print "\e[2J\e[H\e[?25l"

# Create canvas with slower FPS for demo visibility
canvas = Unmagic::Terminal::Canvas.new(fps: 10)

# Define regions for different progress bar demos
canvas.define_region(:title, x: 0, y: 0, width: 80, height: 3, bg: :blue, fg: :white)
canvas.define_region(:demo1, x: 0, y: 4, width: 80, height: 3, border: true)
canvas.define_region(:demo2, x: 0, y: 8, width: 80, height: 4, border: true)
canvas.define_region(:demo3, x: 0, y: 13, width: 80, height: 3, border: true)
canvas.define_region(:demo4, x: 0, y: 17, width: 80, height: 4, border: true)
canvas.define_region(:status, x: 0, y: 22, width: 80, height: 2)

# Set title
canvas.regions[:title] = '  🎯 Canvas Progress Bar Demo'

# Demo 1: Single segment progress
pb1 = CanvasProgressBar.new(width: 60)
pb1.add_segment(:process, max: 100, value: 65, color: :cyan, label: 'Process')
canvas.regions[:demo1] = " Basic Progress:\n #{pb1.render}"

# Demo 2: Multi-segment pipeline
pb2 = CanvasProgressBar.new(width: 60)
pb2.add_segment(:download, max: 100, value: 85, color: :blue, label: 'Download')
pb2.add_segment(:process, max: 50, value: 30, color: :yellow, label: 'Process')
pb2.add_segment(:upload, max: 25, value: 5, color: :green, label: 'Upload')
canvas.regions[:demo2] = " Multi-segment Pipeline:\n #{pb2.render}"

# Demo 3: Build pipeline
pb3 = CanvasProgressBar.new(width: 60)
pb3.add_segment(:lint, max: 10, value: 10, color: :magenta, label: 'Lint')
pb3.add_segment(:test, max: 200, value: 180, color: :yellow, label: 'Tests')
pb3.add_segment(:build, max: 50, value: 30, color: :blue, label: 'Build')
pb3.add_segment(:deploy, max: 5, value: 0, color: :green, label: 'Deploy')
canvas.regions[:demo3] = " Build Pipeline:\n #{pb3.render}"

# Demo 4: Animated progress
pb4 = CanvasProgressBar.new(width: 60)
pb4.add_segment(:download, max: 100, value: 0, color: :cyan, label: 'Download')
pb4.add_segment(:install, max: 50, value: 0, color: :green, label: 'Install')
canvas.regions[:demo4] = " Animated Progress:\n #{pb4.render}"

canvas.regions[:status] = ' Press Ctrl+C to exit'

# Animation thread
Thread.new do
  progress = 0
  direction = 1

  loop do
    sleep(0.1)

    # Update animated progress bar
    pb4.update_segment(:download, progress)
    pb4.update_segment(:install, [ progress - 30, 0 ].max)

    canvas.regions[:demo4] = " Animated Progress:\n #{pb4.render}"

    progress += direction * 2
    if progress >= 100
      direction = -1
    elsif progress <= 0
      direction = 1
    end
  end
end

# Status updates
Thread.new do
  loop do
    sleep(1)
    timestamp = Time.now.strftime('%H:%M:%S')
    canvas.regions[:status] = " Running demo at #{timestamp} - Press Ctrl+C to exit"
  end
end

# Start the canvas - this will block until Ctrl+C
puts 'Starting canvas progress bar demo... Press Ctrl+C to exit.'
begin
  canvas.start # Blocks main thread, handles Ctrl+C automatically
rescue Interrupt
  # Canvas.start already calls stop() on interrupt, but let's be explicit
  canvas.stop
ensure
  # Show cursor and position it below our canvas
  print "\e[?25h\e[25;1H"

  puts 'Canvas progress bar demo terminated.'
end
