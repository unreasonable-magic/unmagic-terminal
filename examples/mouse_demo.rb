#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'unmagic-terminal'

# Demonstrate mouse input capabilities
terminal = Unmagic::Terminal.current

puts 'Mouse Input Demo'
puts '================'
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
      # Read keyboard and mouse events
      key_event = terminal.keyboard.read_event(timeout: 0.01)
      mouse_event = terminal.mouse.read_event(timeout: 0.01) if terminal.mouse.enabled?

      if key_event && %i[escape ctrl_c].include?(key_event.key)
        # Exit on ESC or Ctrl+C
        break
      end

      next unless mouse_event

      # Clear status line and display event
      terminal.move_cursor(1, 18)
      terminal.clear_line

      status = case mouse_event
      when Unmagic::Terminal::Emulator::Generic::MouseClickEvent
                 "Click: button=#{mouse_event.button} at (#{mouse_event.x}, #{mouse_event.y})"
      when Unmagic::Terminal::Emulator::Generic::MouseReleaseEvent
                 "Release: button=#{mouse_event.button} at (#{mouse_event.x}, #{mouse_event.y})"
      when Unmagic::Terminal::Emulator::Generic::MouseDragEvent
                 "Drag: button=#{mouse_event.button} at (#{mouse_event.x}, #{mouse_event.y})"
      when Unmagic::Terminal::Emulator::Generic::MouseMoveEvent
                 "Move: at (#{mouse_event.x}, #{mouse_event.y})"
      when Unmagic::Terminal::Emulator::Generic::MouseScrollEvent
                 "Scroll: #{mouse_event.direction} at (#{mouse_event.x}, #{mouse_event.y})"
      else
                 "Unknown mouse event: #{mouse_event.class}"
      end

      terminal.output.write status
      terminal.output.flush

      # Mark the click position on the grid
      unless mouse_event.is_a?(Unmagic::Terminal::Emulator::Generic::MouseClickEvent) && mouse_event.y >= 6 && mouse_event.y <= 15 && mouse_event.x >= 2 && mouse_event.x <= 41
        next
      end

      terminal.move_cursor(mouse_event.x, mouse_event.y)
      terminal.output.write '●'
      terminal.output.flush
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
