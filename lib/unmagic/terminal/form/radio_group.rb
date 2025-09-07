# frozen_string_literal: true

require_relative "../form"
require_relative "../ansi"

module Unmagic
  module Terminal
    module Form
      # Interactive radio button group for terminal selection
      #
      # Example:
      #   radio = RadioGroup.new(
      #     options: ["Small", "Medium", "Large"],
      #     default: "Medium"
      #   ) do |choice|
      #     puts "You selected: #{choice}"
      #   end
      #   radio.render
      #
      class RadioGroup < Component
        attr_reader :options, :selected_index, :selected_value

        def initialize(options:, default: nil, label: nil, autosubmit: false,
                       terminal: Terminal.current, &block)
          super(terminal: terminal)
          @options = options
          @label = label
          @autosubmit = autosubmit
          @callback = block
          @selected_index = find_default_index(default)
          @selected_value = @options[@selected_index]
          @cancelled = false
        end

        # Render the radio group and handle interaction
        def render
          return if @options.empty?

          # Check if we're in a TTY
          unless @terminal.tty?
            puts "Error: RadioGroup requires an interactive terminal (TTY)"
            return nil
          end

          @terminal.raw_mode do
            @terminal.hide_cursor

            # Enable mouse if supported
            @terminal.mouse.enable(mode: :normal) if @terminal.mouse && @terminal.supports_mouse?

            # Draw initial state
            draw

            # Handle keyboard input
            handle_input
          ensure
            # Clean up
            @terminal.mouse.disable if @terminal.mouse && @terminal.supports_mouse?
            @terminal.show_cursor
            clear_radio_display
          end

          # Return the result
          @cancelled ? nil : @selected_value
        end

        private

        def find_default_index(default)
          return 0 unless default

          index = @options.index(default)
          index || 0
        end

        def draw
          # Save cursor position
          @terminal.save_cursor

          # Draw label if present
          if @label
            puts ANSI.text(@label, style: :bold)
            puts
          end

          # Draw each option
          @options.each_with_index do |option, index|
            draw_option(option, index)
          end

          # Draw help text
          puts
          help_text = if @autosubmit
                        ANSI.text("↑↓ to navigate, ESC to cancel", color: :gray)
          else
                        ANSI.text("↑↓ to navigate, Enter to confirm, ESC to cancel", color: :gray)
          end
          puts help_text
        end

        def draw_option(option, index)
          is_selected = index == @selected_index

          # Radio button symbol
          symbol = is_selected ? "◉" : "○"

          # Apply colors
          line = if is_selected
                   "#{ANSI.text(symbol, color: :green)} #{ANSI.text(option, color: :green, style: :bold)}"
          else
                   "#{symbol} #{option}"
          end

          puts line
        end

        def redraw_option(index)
          # Calculate position from the saved cursor
          # Lines from start: label (2 if present) + option index
          line_offset = index
          line_offset += 2 if @label # Label + blank line

          # Move to the specific line from saved position
          @terminal.restore_cursor
          @terminal.move_cursor_down(line_offset) if line_offset.positive?
          @terminal.clear_line

          # Redraw the option
          is_selected = index == @selected_index
          symbol = is_selected ? "◉" : "○"

          line = if is_selected
                   "#{ANSI.text(symbol, color: :green)} #{ANSI.text(@options[index], color: :green, style: :bold)}"
          else
                   "#{symbol} #{@options[index]}"
          end

          print "\r#{line}"
          $stdout.flush
        end

        def handle_input
          loop do
            event = @terminal.keyboard.read_event
            next unless event

            case event
            when Emulator::Generic::KeyDownEvent
              result = handle_key_event(event)
              break if %i[done cancel].include?(result)
            when Emulator::Generic::MouseClickEvent
              result = handle_mouse_event(event)
              break if %i[done cancel].include?(result)
            end
          end
        end

        def handle_key_event(event)
          case event.key
          when :up, :k # k for vim users
            move_selection(-1)
          when :down, :j # j for vim users
            move_selection(1)
          when :enter, :space
            select_current unless @autosubmit
            :done
          when :escape, :ctrl_c
            @cancelled = true
            :cancel
          when "q"
            @cancelled = true
            :cancel
          else
            # Check for number keys (1-9 to select directly)
            if event.key =~ /^[1-9]$/
              index = event.key.to_i - 1
              if index < @options.length
                change_selection(index)
                if @autosubmit
                  select_current
                  :done
                end
              end
            end
          end
        end

        def handle_mouse_event(event)
          # Calculate which option was clicked
          # This is approximate and would need adjustment based on actual rendering
          return unless event.y.positive? && event.y <= @options.length

          index = event.y - 1
          index -= 2 if @label # Adjust for label

          return unless index >= 0 && index < @options.length

          change_selection(index)
          select_current
          :done
        end

        def move_selection(direction)
          new_index = @selected_index + direction

          # Wrap around
          if new_index.negative?
            new_index = @options.length - 1
          elsif new_index >= @options.length
            new_index = 0
          end

          change_selection(new_index)
        end

        def change_selection(new_index)
          return if new_index == @selected_index

          old_index = @selected_index
          @selected_index = new_index
          @selected_value = @options[@selected_index]

          # Redraw the changed options
          redraw_option(old_index)
          redraw_option(@selected_index)

          # Call callback if autosubmit is enabled
          return unless @autosubmit

          select_current
        end

        def select_current
          @callback&.call(@selected_value)
        end

        def clear_radio_display
          # Move back to start and clear everything we drew
          @terminal.restore_cursor

          # Clear all lines we used
          total_lines = @options.length + 2 # Options + blank line + help text
          total_lines += 2 if @label # Label + blank line

          total_lines.times do |i|
            @terminal.clear_line
            @terminal.move_cursor_down if i < total_lines - 1
          end

          # Move cursor back to original position
          @terminal.restore_cursor
        end
      end
    end
  end
end
