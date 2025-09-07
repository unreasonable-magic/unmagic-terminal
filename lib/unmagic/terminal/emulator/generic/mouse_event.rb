# frozen_string_literal: true

require_relative "../../emulator"

module Unmagic
  module Terminal
    module Emulator
      module Generic
        # Base mouse event
        class MouseEvent < Emulator::Event
          attr_reader :x, :y

          def initialize(x:, y:, raw: nil)
            super(raw: raw)
            @x = x  # Column (1-based)
            @y = y  # Row (1-based)
          end
        end

        # Mouse button press event
        class MouseClickEvent < MouseEvent
          attr_reader :button

          def initialize(x:, y:, button:, raw: nil)
            super(x: x, y: y, raw: raw)
            @button = button # :left, :middle, :right
          end

          def left?
            @button == :left
          end

          def middle?
            @button == :middle
          end

          def right?
            @button == :right
          end
        end

        # Mouse button release event
        class MouseReleaseEvent < MouseEvent
          attr_reader :button

          def initialize(x:, y:, button:, raw: nil)
            super(x: x, y: y, raw: raw)
            @button = button
          end
        end

        # Mouse movement event (with button held)
        class MouseDragEvent < MouseEvent
          attr_reader :button

          def initialize(x:, y:, button:, raw: nil)
            super(x: x, y: y, raw: raw)
            @button = button # Which button is being held
          end
        end

        # Mouse movement event (no buttons held)
        class MouseMoveEvent < MouseEvent
          # Just inherits x, y from MouseEvent
        end

        # Mouse wheel scroll event
        class MouseScrollEvent < MouseEvent
          attr_reader :direction

          def initialize(x:, y:, direction:, raw: nil)
            super(x: x, y: y, raw: raw)
            @direction = direction # :up or :down
          end

          def up?
            @direction == :up
          end

          def down?
            @direction == :down
          end
        end
      end
    end
  end
end
