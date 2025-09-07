# frozen_string_literal: true

module Unmagic
  module Terminal
    class Grid
      # Represents a grid track size (column or row).
      # Can be fixed (pixels/characters), fractional (fr), or auto.
      #
      # Example:
      #
      #   TrackSize.parse("100px")   # Fixed 100 characters
      #   TrackSize.parse("1fr")     # 1 fraction unit
      #   TrackSize.parse("auto")    # Auto-size based on content
      class TrackSize
        attr_reader :type, :size
        attr_accessor :calculated_size

        def initialize(type:, size: nil)
          @type = type # :fixed, :fr, :auto
          @size = size
          @calculated_size = size if type == :fixed
        end

        # Parse a string track size definition
        def self.parse(value)
          case value
          when /^(\d+)(px)?$/
            # Fixed size in pixels/characters
            new(type: :fixed, size: ::Regexp.last_match(1).to_i)
          when /^(\d+(?:\.\d+)?)fr$/
            # Fractional unit
            new(type: :fr, size: ::Regexp.last_match(1).to_f)
          when "auto"
            # Auto sizing
            new(type: :auto)
          else
            # Default to fixed size if just a number
            new(type: :fixed, size: value.to_i)
          end
        end

        # Create from various value types
        def self.from_value(value)
          case value
          when Integer
            new(type: :fixed, size: value)
          when :auto
            new(type: :auto)
          when :fr
            new(type: :fr, size: 1)
          when Hash
            if value[:fr]
              new(type: :fr, size: value[:fr])
            elsif value[:px]
              new(type: :fixed, size: value[:px])
            else
              new(type: :auto)
            end
          else
            parse(value.to_s)
          end
        end

        def fixed?
          @type == :fixed
        end

        def fr?
          @type == :fr
        end

        def auto?
          @type == :auto
        end

        def fr_value
          fr? ? (@size || 1) : 0
        end
      end
    end
  end
end
