# frozen_string_literal: true

require_relative "mouse_event"

module Unmagic
  module Terminal
    module Emulator
      module Generic
        # Handles mouse input for generic terminals
        class Mouse
          def initialize(input: $stdin, output: $stdout)
            @input = input
            @output = output
            @tracking_enabled = false
            @sgr_mode = false # SGR extended mouse mode
          end

          # Enable mouse tracking
          def enable(mode: :basic)
            case mode
            when :basic
              # X10 compatibility mode - just button presses
              @output.write "\e[?9h"
            when :normal
              # Normal tracking - press and release
              @output.write "\e[?1000h"
            when :button_event
              # Also report button motion events
              @output.write "\e[?1002h"
            when :any_event
              # Report all motion events
              @output.write "\e[?1003h"
            end

            # Enable SGR extended coordinates (for terminals > 223 columns/rows)
            @output.write "\e[?1006h"
            @sgr_mode = true

            @output.flush
            @tracking_enabled = true
          end

          # Disable mouse tracking
          def disable
            @output.write "\e[?9l"
            @output.write "\e[?1000l"
            @output.write "\e[?1002l"
            @output.write "\e[?1003l"
            @output.write "\e[?1006l"
            @output.flush
            @tracking_enabled = false
            @sgr_mode = false
          end

          # Check if mouse tracking is enabled
          def enabled?
            @tracking_enabled
          end

          # Read a single mouse event
          def read_event(timeout: nil)
            return nil unless @tracking_enabled

            raw = read_raw_input(timeout)
            return nil unless raw

            parse_event(raw)
          end

          protected

          def parse_event(raw)
            if @sgr_mode && raw =~ /\e\[<(\d+);(\d+);(\d+)([Mm])/
              # SGR extended format: ESC[<button;x;y;M (press) or m (release)
              parse_sgr_event(::Regexp.last_match(1).to_i, ::Regexp.last_match(2).to_i, ::Regexp.last_match(3).to_i,
                              ::Regexp.last_match(4))
            elsif raw =~ /\e\[M(.)(.)(.)/
              # Legacy X10 format: ESC[M<button><x><y>
              parse_x10_event(::Regexp.last_match(1), ::Regexp.last_match(2), ::Regexp.last_match(3))
            else
              nil
            end
          end

          def parse_sgr_event(button_code, x, y, action)
            # SGR button codes:
            # 0-2: left, middle, right
            # 3: release
            # 32-34: drag with left, middle, right
            # 64-65: scroll up, down

            event_type = action == "M" ? :press : :release

            case button_code
            when 0..2
              # Basic button press
              button = %i[left middle right][button_code]
              if event_type == :press
                MouseClickEvent.new(x: x, y: y, button: button, raw: nil)
              else
                MouseReleaseEvent.new(x: x, y: y, button: button, raw: nil)
              end
            when 32..34
              # Drag event
              button = %i[left middle right][button_code - 32]
              MouseDragEvent.new(x: x, y: y, button: button, raw: nil)
            when 64
              # Scroll up
              MouseScrollEvent.new(x: x, y: y, direction: :up, raw: nil)
            when 65
              # Scroll down
              MouseScrollEvent.new(x: x, y: y, direction: :down, raw: nil)
            else
              # Motion or other event
              MouseMoveEvent.new(x: x, y: y, raw: nil)
            end
          end

          def parse_x10_event(button_byte, x_byte, y_byte)
            # X10 format uses byte values offset by 32
            button_code = button_byte.ord - 32
            x = x_byte.ord - 32
            y = y_byte.ord - 32

            # Extract button from lower 2 bits
            button_num = button_code & 0b11
            button = case button_num
            when 0 then :left
            when 1 then :middle
            when 2 then :right
            else :unknown
            end

            # Check for scroll events (bit 6 set)
            if button_code & 0b01000000 != 0
              direction = button_num.zero? ? :up : :down
              MouseScrollEvent.new(x: x, y: y, direction: direction, raw: nil)
            elsif button_code & 0b00100000 != 0
              # Motion event (bit 5 set)
              MouseDragEvent.new(x: x, y: y, button: button, raw: nil)
            else
              # Regular click
              MouseClickEvent.new(x: x, y: y, button: button, raw: nil)
            end
          end

          def read_raw_input(timeout = nil)
            require "io/console"

            # If input is not a TTY, just return nil
            return nil unless @input.respond_to?(:raw)

            if timeout
              ready = IO.select([ @input ], nil, nil, timeout)
              return nil unless ready
            end

            # Read the escape sequence
            char = @input.getc
            return nil unless char

            if char == "\e"
              seq = char

              # Read the rest of the mouse sequence
              while IO.select([ @input ], nil, nil, 0.001)
                next_char = @input.getc
                break unless next_char

                seq += next_char

                # Stop at terminator for SGR mode or after 6 bytes for X10
                break if seq =~ /[Mm]$/ || seq.length >= 6
              end

              seq
            else
              char
            end
          end
        end
      end
    end
  end
end
