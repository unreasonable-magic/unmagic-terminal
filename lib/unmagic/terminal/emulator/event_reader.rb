# frozen_string_literal: true

module Unmagic
  module Terminal
    module Emulator
      # Unified event reader that can read keyboard, mouse, and resize events
      # from the same input stream without conflicts
      class EventReader
        def initialize(keyboard:, mouse:, input: $stdin, emulator: nil)
          @input = input
          @keyboard = keyboard
          @mouse = mouse
          @emulator = emulator
          @resize_queue = Queue.new

          # Set up resize event handler if emulator provided
          return unless @emulator

          @emulator.on_resize do |event|
            @resize_queue << event
          end
        end

        # Read the next event (keyboard, mouse, or resize)
        def read_event(timeout: nil)
          # Check for queued resize events first
          unless @resize_queue.empty?
            begin
              return @resize_queue.pop(true)
            rescue StandardError
              nil
            end
          end

          return nil unless @input.respond_to?(:getc)

          if timeout
            # Check for input or resize events
            start_time = Time.now
            loop do
              # Check resize queue again
              unless @resize_queue.empty?
                begin
                  return @resize_queue.pop(true)
                rescue StandardError
                  nil
                end
              end

              # Check for input
              ready = IO.select([ @input ], nil, nil, 0.01)
              break if ready

              # Check if timeout exceeded
              return nil if Time.now - start_time > timeout
            end
          end

          # Read first byte
          char = @input.getc
          return nil unless char

          if char == "\e"
            # Escape sequence - could be keyboard or mouse
            seq = char

            # Read more bytes if available
            while IO.select([ @input ], nil, nil, 0.001)
              next_char = @input.getc
              break unless next_char

              seq += next_char

              # Stop at terminators
              # Mouse: ends with M or m
              # Keyboard: ends with A-Z or ~
              break if seq =~ /[Mm]$/ || seq =~ /[A-Z~]$/
            end

            # Determine if it's a mouse or keyboard event
            if seq =~ /\e\[<.*[Mm]$/ || seq =~ /\e\[M/
              # Mouse event - delegate to mouse parser
              @mouse.send(:parse_event, seq) if @mouse.enabled?
            else
              # Keyboard event - delegate to keyboard parser
              @keyboard.send(:parse_event, seq)
            end
          else
            # Regular character - it's a keyboard event
            @keyboard.send(:parse_event, char)
          end
        end
      end
    end
  end
end
