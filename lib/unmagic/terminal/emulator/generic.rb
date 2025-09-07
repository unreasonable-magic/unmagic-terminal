# frozen_string_literal: true

require_relative "../emulator"
require_relative "generic/keyboard"
require_relative "generic/mouse"
require_relative "event_reader"

module Unmagic
  module Terminal
    module Emulator
      module Generic
        # Generic terminal emulator that works with standard ANSI terminals
        class Generic < Emulator::Base
          attr_reader :keyboard, :mouse, :event_reader

          def initialize(input: $stdin, output: $stdout)
            super
            @keyboard = Keyboard.new(input: input, output: output)
            @mouse = Mouse.new(input: input, output: output)
            @event_reader = EventReader.new(input: input, keyboard: @keyboard, mouse: @mouse, emulator: self)
          end

          # Alternative screen buffer (useful for full-screen apps)
          def enter_alternate_screen
            write "\e[?1049h"
          end

          def exit_alternate_screen
            write "\e[?1049l"
          end

          # Set terminal title
          def set_title(title)
            write "\e]0;#{title}\a"
          end

          # Bell/beep
          def bell
            write "\a"
          end
        end
      end
    end
  end
end
