# frozen_string_literal: true

module Unmagic
  module Terminal
    module Emulator
      # Base class for all terminal events (keyboard, mouse, resize, etc.)
      class Event
        attr_reader :timestamp, :raw

        def initialize(raw: nil)
          @timestamp = Time.now
          @raw = raw # Original input bytes/sequence for debugging
        end
      end

      # Terminal resize event (triggered by SIGWINCH)
      class ResizeEvent < Event
        attr_reader :width, :height, :old_width, :old_height

        def initialize(width:, height:, old_width: nil, old_height: nil, **kwargs)
          super(**kwargs)
          @width = width
          @height = height
          @old_width = old_width
          @old_height = old_height
        end

        def changed?
          @old_width != @width || @old_height != @height
        end

        def to_s
          "ResizeEvent: #{@old_width}x#{@old_height} -> #{@width}x#{@height}"
        end
      end

      # Abstract base class for terminal emulators
      class Base
        attr_reader :input, :output

        def initialize(input: $stdin, output: $stdout)
          @input = input
          @output = output
          @resize_handlers = []
          @previous_size = size
          @sigwinch_installed = false
        end

        # Terminal capabilities - subclasses override to indicate support
        def supports_enhanced_keyboard? = false
        def supports_mouse? = false
        def supports_graphics? = false
        def supports_unicode? = true
        def supports_256_colors? = true
        def supports_true_color? = false
        def supports_hyperlinks? = false

        # Screen control operations
        def clear
          write "\e[2J\e[H"
        end

        def clear_line
          write "\e[2K"
        end

        def clear_to_end_of_line
          write "\e[0K"
        end

        def move_cursor(x, y)
          write "\e[#{y};#{x}H"
        end

        def move_cursor_up(lines = 1)
          write "\e[#{lines}A"
        end

        def move_cursor_down(lines = 1)
          write "\e[#{lines}B"
        end

        def move_cursor_forward(cols = 1)
          write "\e[#{cols}C"
        end

        def move_cursor_back(cols = 1)
          write "\e[#{cols}D"
        end

        def hide_cursor
          write "\e[?25l"
        end

        def show_cursor
          write "\e[?25h"
        end

        def save_cursor
          write "\e[s"
        end

        def restore_cursor
          write "\e[u"
        end

        # Terminal size
        def size
          require "io/console"
          @input.winsize
        rescue StandardError
          [ 24, 80 ] # Default fallback
        end

        def width
          size[1]
        end

        def height
          size[0]
        end

        # Raw mode for reading input without line buffering
        def raw_mode(&block)
          require "io/console"
          @input.raw(&block)
        end

        # Check if terminal is a TTY
        def tty?
          @input.tty? && @output.tty?
        end

        # Register a handler for resize events
        def on_resize(&block)
          @resize_handlers << block
          install_sigwinch_handler unless @sigwinch_installed
        end

        # Enable SIGWINCH signal handling for resize events
        def enable_resize_events
          install_sigwinch_handler unless @sigwinch_installed
        end

        # Disable SIGWINCH signal handling
        def disable_resize_events
          uninstall_sigwinch_handler if @sigwinch_installed
        end

        # Manually check for resize (useful for polling)
        def check_resize
          current_size = size
          return unless current_size != @previous_size

          old_height, old_width = @previous_size
          new_height, new_width = current_size

          event = ResizeEvent.new(
            width: new_width,
            height: new_height,
            old_width: old_width,
            old_height: old_height
          )

          @previous_size = current_size
          trigger_resize_event(event)
          event
        end

        protected

        def install_sigwinch_handler
          return unless tty?

          @sigwinch_installed = true
          @original_sigwinch = Signal.trap("WINCH") do
            check_resize
            @original_sigwinch.call if @original_sigwinch.respond_to?(:call)
          end
        rescue ArgumentError
          # SIGWINCH not supported on this platform
          @sigwinch_installed = false
        end

        def uninstall_sigwinch_handler
          return unless @sigwinch_installed

          Signal.trap("WINCH", @original_sigwinch || "DEFAULT")
          @sigwinch_installed = false
        end

        def trigger_resize_event(event)
          @resize_handlers.each { |handler| handler.call(event) }
        end

        def write(data)
          @output.write(data)
          @output.flush
        end
      end
    end
  end
end
