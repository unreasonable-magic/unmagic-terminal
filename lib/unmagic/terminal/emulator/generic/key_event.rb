# frozen_string_literal: true

require_relative "../../emulator"

module Unmagic
  module Terminal
    module Emulator
      module Generic
        # Represents a keyboard key press event
        class KeyDownEvent < Emulator::Event
          attr_reader :key, :modifiers

          def initialize(key:, modifiers: [], raw: nil)
            super(raw: raw)
            @key = key # Symbol like :up, :enter or String like "a", "B"
            @modifiers = modifiers # Array of [:shift, :ctrl, :alt, :super]
          end

          # Helper methods for checking modifiers
          def ctrl?
            @modifiers.include?(:ctrl)
          end

          def alt?
            @modifiers.include?(:alt)
          end

          def shift?
            @modifiers.include?(:shift)
          end

          def super?
            @modifiers.include?(:super)
          end

          # Check if this is a special key (not a character)
          def special?
            @key.is_a?(Symbol)
          end

          # Check if this is a regular character
          def char?
            @key.is_a?(String)
          end

          # Human-readable representation
          def to_s
            parts = @modifiers.map { |m| m.to_s.capitalize }
            key_str = @key.is_a?(Symbol) ? @key.to_s.capitalize : @key
            parts << key_str
            parts.join("+")
          end

          # Check if this event matches a pattern
          def matches?(pattern)
            case pattern
            when Symbol
              # Simple symbol match: :enter, :up, :a
              @key == pattern && @modifiers.empty?
            when String
              if pattern.include?("+")
                # Modifier syntax: "ctrl+s", "alt+shift+f"
                to_s.downcase == pattern.downcase
              else
                # Simple character match
                @key == pattern && @modifiers.empty?
              end
            when Hash
              # Explicit hash match: {key: :s, modifiers: [:ctrl]}
              pattern[:key] == @key &&
                (pattern[:modifiers] || []).sort == @modifiers.sort
            else
              false
            end
          end
        end

        # Represents a keyboard key release event
        class KeyUpEvent < KeyDownEvent
          # Inherits everything from KeyDownEvent, just a different type
        end

        # Represents a key repeat event (when holding a key)
        class KeyRepeatEvent < KeyDownEvent
          # Inherits everything from KeyDownEvent, just a different type
        end
      end
    end
  end
end
