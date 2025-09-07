#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'unmagic-terminal'

# Demonstrate mouse input capabilities with unified event reader
terminal = Unmagic::Terminal.current

puts 'Mouse Input Demo (Unified Event Reader)'
puts '======================================='
puts "Your terminal: #{terminal.class.name.split('::').last}"
puts "Mouse support: #{terminal.supports_mouse? ? 'Yes' : 'No'}"
puts

unless terminal.supports_mouse?
  puts "Your terminal doesn't support mouse input."
  exit 1
end

puts 'Enabling mouse tracking...'
terminal.mouse.enable(mode: :any_event)
puts 'Mouse tracking enabled!'
puts
puts 'Click, drag, or scroll in the terminal (ESC to exit):'
puts '------------------------------------------------------'

begin
  terminal.raw_mode do
    terminal.hide_cursor

    # Draw a simple grid for reference
    10.times do |y|
      terminal.move_cursor(1, y + 6)
      terminal.output.write "│#{'·' * 40}│"
    end
    terminal.output.flush

    loop do
      # Use the unified event reader
      event = terminal.event_reader.read_event(timeout: 0.01)

      next unless event

      case event
      when Unmagic::Terminal::Emulator::Generic::KeyDownEvent
        # Exit on ESC or Ctrl+C
        break if %i[escape ctrl_c].include?(event.key)

      when Unmagic::Terminal::Emulator::Generic::MouseClickEvent
        # Clear status line and display event
        terminal.move_cursor(1, 18)
        terminal.clear_line
        terminal.output.write "Click: button=#{event.button} at (#{event.x}, #{event.y})"
        terminal.output.flush

        # Mark click position on the grid
        if event.y >= 6 && event.y <= 15 && event.x >= 2 && event.x <= 41
          terminal.move_cursor(event.x, event.y)
          terminal.output.write '●'
          terminal.output.flush
        end

      when Unmagic::Terminal::Emulator::Generic::MouseReleaseEvent
        terminal.move_cursor(1, 18)
        terminal.clear_line
        terminal.output.write "Release: button=#{event.button} at (#{event.x}, #{event.y})"
        terminal.output.flush

      when Unmagic::Terminal::Emulator::Generic::MouseDragEvent
        terminal.move_cursor(1, 18)
        terminal.clear_line
        terminal.output.write "Drag: button=#{event.button} at (#{event.x}, #{event.y})"
        terminal.output.flush

      when Unmagic::Terminal::Emulator::Generic::MouseMoveEvent
        terminal.move_cursor(1, 18)
        terminal.clear_line
        terminal.output.write "Move: at (#{event.x}, #{event.y})"
        terminal.output.flush

      when Unmagic::Terminal::Emulator::Generic::MouseScrollEvent
        terminal.move_cursor(1, 18)
        terminal.clear_line
        terminal.output.write "Scroll: #{event.direction} at (#{event.x}, #{event.y})"
        terminal.output.flush
      end
    end
  ensure
    terminal.show_cursor
    terminal.mouse.disable
  end
rescue Interrupt
  # Clean exit
ensure
  terminal.clear
  puts 'Mouse demo ended!'
end
