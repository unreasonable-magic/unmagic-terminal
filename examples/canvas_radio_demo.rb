#!/usr/bin/env ruby
# frozen_string_literal: true

# Demo showing how radio buttons could use canvas regions for efficient updates
$LOAD_PATH.unshift(File.expand_path('../../unmagic-color/lib', __dir__))
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'unmagic-terminal'
require 'unmagic/terminal/canvas'
require 'io/console'

class CanvasRadioGroup
  def initialize(options:, default: nil, label: nil)
    @options = options
    @selected_index = default ? @options.index(default) : 0
    @label = label
    @canvas = nil
    @running = true
  end

  def render
    setup_terminal
    create_canvas

    # Initial render
    update_display

    # Handle keyboard input
    handle_input

    # Return selected value
    @options[@selected_index]
  ensure
    cleanup
  end

  private

  def setup_terminal
    # Hide cursor
    print "\e[?25l"
    # Clear screen
    print "\e[2J\e[H"

    # Raw mode for input
    $stdin.raw!
  end

  def cleanup
    @canvas&.stop
    $stdin.cooked!
    # Show cursor
    print "\e[?25h"
    # Move below the rendered area
    print "\e[10;1H"
  end

  def create_canvas
    @canvas = Unmagic::Terminal::Canvas.new

    # Define regions
    if @label
      @canvas.define_region(:label, x: 0, y: 0, width: 50, height: 1)
      @canvas.define_region(:options, x: 0, y: 2, width: 50, height: @options.length)
      @canvas.define_region(:help, x: 0, y: 3 + @options.length, width: 50, height: 1)
    else
      @canvas.define_region(:options, x: 0, y: 0, width: 50, height: @options.length)
      @canvas.define_region(:help, x: 0, y: 1 + @options.length, width: 50, height: 1)
    end

    # Set label if provided
    @canvas.regions[:label] = @label if @label

    # Set help text
    @canvas.regions[:help] = '↑/↓: Navigate  Enter: Select  q: Quit'
  end

  def update_display
    # Build the options display
    lines = @options.map.with_index do |option, index|
      if index == @selected_index
        "→ ◉ #{option}"  # Selected with arrow
      else
        "  ○ #{option}"  # Not selected
      end
    end

    # Update the options region
    @canvas.regions[:options] = lines.join("\n")
  end

  def handle_input
    while @running
      char = $stdin.getc

      case char
      when "\e" # Escape sequence
        if $stdin.ready?
          next_char = $stdin.getc
          if next_char == '['
            arrow = $stdin.getc
            case arrow
            when 'A'  # Up arrow
              move_selection(-1)
            when 'B'  # Down arrow
              move_selection(1)
            end
          end
        else
          # Just escape key
          @running = false
        end
      when "\r", "\n" # Enter
        @running = false
      when 'q', 'Q', "\x03" # q or Ctrl+C
        @selected_index = nil
        @running = false
      end
    end
  end

  def move_selection(delta)
    new_index = @selected_index + delta
    return unless new_index >= 0 && new_index < @options.length

    @selected_index = new_index
    update_display
  end
end

# Demo usage
puts "Starting Canvas-based Radio Demo\n\n"
sleep 1

radio = CanvasRadioGroup.new(
  options: %w[Red Blue Green Yellow Purple],
  default: 'Blue',
  label: 'Pick your favorite color:'
)

result = radio.render

if result
  puts "You selected: #{result}"
else
  puts 'Selection cancelled'
end

puts "\nNow testing with more options and no label:\n"
sleep 1

radio2 = CanvasRadioGroup.new(
  options: [ 'Option 1', 'Option 2', 'Option 3', 'Option 4', 'Option 5', 'Option 6', 'Option 7' ],
  default: 'Option 3'
)

result2 = radio2.render

if result2
  puts "You selected: #{result2}"
else
  puts 'Selection cancelled'
end

puts "\nDemo complete!"
