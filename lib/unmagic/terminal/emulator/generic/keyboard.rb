# frozen_string_literal: true

require_relative "key_event"

module Unmagic
  module Terminal
    module Emulator
      module Generic
        # Handles keyboard input for generic terminals
        class Keyboard
          # Map of escape sequences to key symbols
          ESCAPE_SEQUENCES = {
            # Arrow keys
            "\e[A" => :up,
            "\e[B" => :down,
            "\e[C" => :right,
            "\e[D" => :left,
            "\eOA" => :up, # Alternative arrow keys
            "\eOB" => :down,
            "\eOC" => :right,
            "\eOD" => :left,

            # Function keys
            "\eOP" => :f1,
            "\eOQ" => :f2,
            "\eOR" => :f3,
            "\eOS" => :f4,
            "\e[15~" => :f5,
            "\e[17~" => :f6,
            "\e[18~" => :f7,
            "\e[19~" => :f8,
            "\e[20~" => :f9,
            "\e[21~" => :f10,
            "\e[23~" => :f11,
            "\e[24~" => :f12,

            # Navigation keys
            "\e[H" => :home,
            "\e[F" => :end,
            "\e[5~" => :page_up,
            "\e[6~" => :page_down,
            "\e[2~" => :insert,
            "\e[3~" => :delete,

            # Modified arrow keys (Ctrl)
            "\e[1;5A" => :ctrl_up,
            "\e[1;5B" => :ctrl_down,
            "\e[1;5C" => :ctrl_right,
            "\e[1;5D" => :ctrl_left,

            # Modified arrow keys (Alt)
            "\e[1;3A" => :alt_up,
            "\e[1;3B" => :alt_down,
            "\e[1;3C" => :alt_right,
            "\e[1;3D" => :alt_left,

            # Modified arrow keys (Shift)
            "\e[1;2A" => :shift_up,
            "\e[1;2B" => :shift_down,
            "\e[1;2C" => :shift_right,
            "\e[1;2D" => :shift_left,

            # Special sequences
            "\e[Z" => :shift_tab
          }.freeze

          # Single byte special characters
          SPECIAL_CHARS = {
            "\r" => :enter,
            "\n" => :enter,
            "\t" => :tab,
            "\e" => :escape,
            "\x7F" => :backspace,
            "\x08" => :backspace,
            " " => :space
          }.freeze

          def initialize(input: $stdin, output: $stdout)
            @input = input
            @output = output
            @buffer = ""
          end

          # Read a single keyboard event
          def read_event(timeout: nil)
            raw = read_raw_input(timeout)
            return nil unless raw

            parse_event(raw)
          end

          # Read multiple events (useful for pasted text)
          def read_events(timeout: 0.01)
            events = []

            while (event = read_event(timeout: timeout))
              events << event
              timeout = 0.001 # Very short timeout for subsequent reads
            end

            events
          end

          protected

          def parse_event(raw)
            # First check for special single-byte characters
            return KeyDownEvent.new(key: SPECIAL_CHARS[raw], raw: raw) if SPECIAL_CHARS[raw]

            # Check for escape sequences
            return parse_escape_sequence(raw) if raw.start_with?("\e")

            # Check for control characters (Ctrl+letter)
            return parse_control_char(raw) if raw.length == 1 && raw.ord < 32

            # Regular character
            KeyDownEvent.new(key: raw, raw: raw)
          end

          def parse_escape_sequence(seq)
            # Check known escape sequences
            if ESCAPE_SEQUENCES[seq]
              key = ESCAPE_SEQUENCES[seq]

              # Extract modifiers from compound keys
              if key.to_s.include?("_")
                parts = key.to_s.split("_")
                modifiers = []
                key_name = parts.last.to_sym

                modifiers << :ctrl if parts.include?("ctrl")
                modifiers << :alt if parts.include?("alt")
                modifiers << :shift if parts.include?("shift")

                KeyDownEvent.new(key: key_name, modifiers: modifiers, raw: seq)
              else
                KeyDownEvent.new(key: key, raw: seq)
              end
            elsif seq.length == 2 && seq[0] == "\e"
              # Alt+key combination (ESC followed by character)
              KeyDownEvent.new(key: seq[1], modifiers: [ :alt ], raw: seq)
            else
              # Unknown escape sequence, return as-is
              KeyDownEvent.new(key: seq, raw: seq)
            end
          end

          def parse_control_char(char)
            # Control characters: Ctrl+A = 1, Ctrl+B = 2, etc.
            case char.ord
            when 3
              # Ctrl+C - special handling
              KeyDownEvent.new(key: :ctrl_c, raw: char)
            when 4
              # Ctrl+D
              KeyDownEvent.new(key: :ctrl_d, raw: char)
            when 26
              # Ctrl+Z
              KeyDownEvent.new(key: :ctrl_z, raw: char)
            when 27
              # ESC key
              KeyDownEvent.new(key: :escape, raw: char)
            else
              # Other control characters (1-31)
              letter = (char.ord + 64).chr.downcase
              KeyDownEvent.new(key: letter, modifiers: [ :ctrl ], raw: char)
            end
          end

          def read_raw_input(timeout = nil)
            # Use raw mode to read without line buffering
            require "io/console"

            # If input is not a TTY, just return nil
            return nil unless @input.respond_to?(:raw)

            if timeout
              # Use IO.select for timeout
              ready = IO.select([ @input ], nil, nil, timeout)
              return nil unless ready
            end

            # Read first byte
            char = @input.getc
            return nil unless char

            # If it's an escape sequence, try to read more
            if char == "\e"
              seq = char

              # Read more bytes if available (with very short timeout)
              while IO.select([ @input ], nil, nil, 0.001)
                next_char = @input.getc
                break unless next_char

                seq += next_char

                # Stop if we hit a terminator
                break if seq =~ /[A-Z~]/
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
