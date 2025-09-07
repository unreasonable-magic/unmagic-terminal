#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'unmagic-terminal'
require 'io/console'

# Demonstrate mouse input capabilities
terminal = Unmagic::Terminal.current

puts 'Mouse Input Demo (Fixed)'
puts '======================='
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
      # Read any input with a timeout
      next unless IO.select([ $stdin ], nil, nil, 0.01)

      # Read the raw input
      char = $stdin.getc
      next unless char

      if char == "\e"
        # Escape sequence - could be keyboard or mouse
        seq = char

        # Read more bytes if available
        while IO.select([ $stdin ], nil, nil, 0.001)
          next_char = $stdin.getc
          break unless next_char

          seq += next_char

          # Stop at mouse terminator or keyboard terminator
          break if seq =~ /[Mm]$/ || seq =~ /[A-Z~]$/
        end

        # Check if it's a mouse event
        if seq =~ /^\e\[<(\d+);(\d+);(\d+)([Mm])/
          # SGR mouse format
          button_code = Regexp.last_match(1).to_i
          x = Regexp.last_match(2).to_i
          y = Regexp.last_match(3).to_i
          action = Regexp.last_match(4)

          # Clear status line and display event
          terminal.move_cursor(1, 18)
          terminal.clear_line

          status = case button_code
          when 0..2
                     button = %i[left middle right][button_code]
                     action == 'M' ? "Click: button=#{button} at (#{x}, #{y})" : "Release: button=#{button} at (#{x}, #{y})"
          when 32..34
                     button = %i[left middle right][button_code - 32]
                     "Drag: button=#{button} at (#{x}, #{y})"
          when 64
                     "Scroll: up at (#{x}, #{y})"
          when 65
                     "Scroll: down at (#{x}, #{y})"
          else
                     "Move: at (#{x}, #{y})"
          end

          terminal.output.write status
          terminal.output.flush

          # Mark click position on the grid
          if button_code >= 0 && button_code <= 2 && action == 'M' && y >= 6 && y <= 15 && x >= 2 && x <= 41
            terminal.move_cursor(x, y)
            terminal.output.write '●'
            terminal.output.flush
          end
        elsif [ "\e", "\e[" ].include?(seq)
          # Just ESC key
          break
        end
      elsif char == "\x03" # Ctrl+C
        break
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
