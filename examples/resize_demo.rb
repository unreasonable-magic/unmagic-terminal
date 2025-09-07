#!/usr/bin/env ruby
# frozen_string_literal: true

# Demo showing terminal resize event handling
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'unmagic/terminal/emulator/generic'
require 'unmagic/terminal/buffer'

# Create emulator
emulator = Unmagic::Terminal::Emulator::Generic::Generic.new

# Track resize events
resize_count = 0
events = []

# Set up resize handler
emulator.on_resize do |event|
  resize_count += 1
  events << event
end

# Enable resize events
emulator.enable_resize_events

# Enter alternate screen for clean display
emulator.enter_alternate_screen
emulator.clear
emulator.hide_cursor

# Function to draw the current state
def draw_screen(emulator, resize_count, events)
  emulator.clear

  # Get current size
  width = emulator.width
  height = emulator.height

  # Create header
  header = Unmagic::Terminal::Buffer.new(
    value: 'Terminal Resize Demo',
    width: width,
    height: 1
  )

  # Create size info
  info_text = "Current size: #{width}x#{height} | Resize events: #{resize_count}"
  info = Unmagic::Terminal::Buffer.new(
    value: info_text,
    width: width,
    height: 1
  )

  # Create instructions
  instructions = Unmagic::Terminal::Buffer.new(
    value: "Resize your terminal window to see events! Press 'q' to quit.",
    width: width,
    height: 1
  )

  # Create event history (last 5 events)
  history_lines = [ '', 'Recent resize events:', '' ]
  events.last(5).each do |event|
    history_lines << "  #{event}"
  end

  history = Unmagic::Terminal::Buffer.new(
    value: history_lines.join("\n"),
    width: width,
    height: history_lines.size
  )

  # Build the screen
  screen = header <<
           Unmagic::Terminal::Buffer.new(value: '', width: width, height: 1) <<
           info <<
           Unmagic::Terminal::Buffer.new(value: '', width: width, height: 1) <<
           instructions <<
           history

  # Draw a border around the entire terminal
  border_top = "┌#{'─' * (width - 2)}┐"
  border_bottom = "└#{'─' * (width - 2)}┘"

  # Output the screen
  emulator.move_cursor(1, 1)
  puts border_top

  screen.to_s.lines.each_with_index do |line, i|
    emulator.move_cursor(1, i + 2)
    print "│ #{line.chomp.ljust(width - 4)} │"
  end

  # Fill remaining space
  content_height = screen.height + 2 # +2 for top and bottom border
  while content_height < height - 1
    emulator.move_cursor(1, content_height)
    print "│#{' ' * (width - 2)}│"
    content_height += 1
  end

  emulator.move_cursor(1, height)
  print border_bottom

  $stdout.flush
end

# Initial draw
draw_screen(emulator, resize_count, events)

# Main event loop
begin
  loop do
    # Read events with timeout to check for resize
    event = emulator.event_reader.read_event(timeout: 0.1)

    if event
      case event
      when Unmagic::Terminal::Emulator::ResizeEvent
        # Redraw on resize
        draw_screen(emulator, resize_count, events)
      else
        # Check for 'q' to quit
        break if event.respond_to?(:char) && event.char == 'q'
      end
    end

    # Periodically check for resize (backup for SIGWINCH)
    draw_screen(emulator, resize_count, events) if emulator.check_resize
  end
ensure
  # Clean up
  emulator.disable_resize_events
  emulator.clear
  emulator.show_cursor
  emulator.exit_alternate_screen

  puts "\nResize demo ended."
  puts "Total resize events detected: #{resize_count}"
end
