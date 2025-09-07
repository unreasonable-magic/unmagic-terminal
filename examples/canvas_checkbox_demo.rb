#!/usr/bin/env ruby
# frozen_string_literal: true

# Demo showing checkboxes with canvas regions for efficient updates
$LOAD_PATH.unshift(File.expand_path('../../unmagic-color/lib', __dir__))
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'unmagic-terminal'
require 'unmagic/terminal/canvas'
require 'io/console'

class CanvasCheckboxList
  def initialize(options:, selected: [], label: nil)
    @options = options
    @selected = selected.map { |opt| @options.index(opt) }.compact
    @current_index = 0
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

    # Return selected values
    @selected.map { |i| @options[i] }
  ensure
    cleanup
  end

  private

  def setup_terminal
    print "\e[?25l" # Hide cursor
    print "\e[2J\e[H" # Clear screen
    $stdin.raw!
  end

  def cleanup
    @canvas&.stop
    $stdin.cooked!
    print "\e[?25h" # Show cursor
    print "\e[15;1H" # Move below
  end

  def create_canvas
    @canvas = Unmagic::Terminal::Canvas.new

    # Calculate heights
    label_height = @label ? 2 : 0

    # Define regions
    if @label
      @canvas.define_region(:label, x: 0, y: 0, width: 60, height: 1)
      @canvas.regions[:label] = @label
    end

    @canvas.define_region(:options, x: 0, y: label_height, width: 60, height: @options.length)
    @canvas.define_region(:status, x: 0, y: label_height + @options.length + 1, width: 60, height: 1, fg: :cyan)
    @canvas.define_region(:help, x: 0, y: label_height + @options.length + 2, width: 60, height: 2)

    # Set help text
    @canvas.regions[:help] = "↑/↓: Navigate  Space: Toggle  a: Select All  n: None\nEnter: Confirm  q: Cancel"
  end

  def update_display
    # Build the options display
    lines = @options.map.with_index do |option, index|
      checkbox = @selected.include?(index) ? '☑' : '☐'
      arrow = index == @current_index ? '→' : ' '
      "#{arrow} #{checkbox} #{option}"
    end

    @canvas.regions[:options] = lines.join("\n")

    # Update status
    count = @selected.length
    @canvas.regions[:status] = "Selected: #{count}/#{@options.length}"
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
              move_cursor(-1)
            when 'B'  # Down arrow
              move_cursor(1)
            end
          end
        else
          @running = false
        end
      when ' ' # Space - toggle current
        toggle_current
      when 'a', 'A'  # Select all
        select_all
      when 'n', 'N'  # Select none
        select_none
      when "\r", "\n" # Enter
        @running = false
      when 'q', 'Q', "\x03" # q or Ctrl+C
        @selected = []
        @running = false
      end
    end
  end

  def move_cursor(delta)
    new_index = @current_index + delta
    return unless new_index >= 0 && new_index < @options.length

    @current_index = new_index
    update_display
  end

  def toggle_current
    if @selected.include?(@current_index)
      @selected.delete(@current_index)
    else
      @selected << @current_index
      @selected.sort!
    end
    update_display
  end

  def select_all
    @selected = (0...@options.length).to_a
    update_display
  end

  def select_none
    @selected = []
    update_display
  end
end

# Demo usage
puts 'Canvas-based Checkbox Demo'
puts '=' * 30
puts "\nPress any key to start..."
$stdin.getch

checkboxes = CanvasCheckboxList.new(
  options: [
    'Ruby',
    'Python',
    'JavaScript',
    'TypeScript',
    'Go',
    'Rust',
    'Java',
    'C++',
    'Swift',
    'Kotlin'
  ],
  selected: %w[Ruby TypeScript],
  label: 'Select your favorite programming languages:'
)

selected = checkboxes.render

if selected.any?
  puts "\nYou selected:"
  selected.each { |lang| puts "  • #{lang}" }
else
  puts "\nNo selection made"
end

puts "\nDemo complete!"
