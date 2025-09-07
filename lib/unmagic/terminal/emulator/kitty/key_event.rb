# frozen_string_literal: true

require_relative "../generic/key_event"

module Unmagic
  module Terminal
    module Emulator
      module Kitty
        # Enhanced key event with Kitty protocol support
        class KeyDownEvent < Generic::KeyDownEvent
          attr_reader :unicode_codepoint, :shifted_codepoint, :base_layout_codepoint, :event_type

          def initialize(key:, modifiers: [], unicode_codepoint: nil,
                         shifted_codepoint: nil, base_layout_codepoint: nil,
                         event_type: :press, raw: nil)
            super(key: key, modifiers: modifiers, raw: raw)
            @unicode_codepoint = unicode_codepoint  # The actual Unicode codepoint
            @shifted_codepoint = shifted_codepoint  # Codepoint with shift applied
            @base_layout_codepoint = base_layout_codepoint # Base layout key
            @event_type = event_type # :press, :repeat, :release
          end

          # Check if this is a key repeat (from holding the key)
          def repeat?
            @event_type == :repeat
          end

          # Check if this is the initial press
          def press?
            @event_type == :press
          end

          # Get the physical key that was pressed (layout-independent)
          def physical_key
            if @base_layout_codepoint
              [ @base_layout_codepoint ].pack("U")
            else
              @key
            end
          end
        end

        # Key release event with Kitty protocol support
        class KeyUpEvent < KeyDownEvent
          def initialize(key:, modifiers: [], unicode_codepoint: nil,
                         shifted_codepoint: nil, base_layout_codepoint: nil, raw: nil)
            super(
              key: key,
              modifiers: modifiers,
              unicode_codepoint: unicode_codepoint,
              shifted_codepoint: shifted_codepoint,
              base_layout_codepoint: base_layout_codepoint,
              event_type: :release,
              raw: raw
            )
          end

          def release?
            true
          end

          def press?
            false
          end
        end
      end
    end
  end
end
