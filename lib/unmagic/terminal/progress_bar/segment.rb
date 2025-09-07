# frozen_string_literal: true

module Unmagic
  module Terminal
    class ProgressBar
      # Individual segment within a progress bar. Each segment tracks its own
      # value/max ratio, color, and optional label for display.
      #
      # Example:
      #
      #   segment = ProgressBar::Segment.new(id: :download, max: 100, color: :blue)
      #   segment.value = 75
      #   segment.percentage  #=> 75.0
      class Segment
        class Error < StandardError; end

        attr_accessor :color, :label, :value
        attr_reader :id, :max

        def initialize(id:, max: 1, color: :green, label: nil)
          @id = id
          @max = max
          @color = color
          @label = label
          @value = 0
        end

        # Calculate percentage completion (0.0 to 100.0)
        def percentage
          return 0.0 if @max <= 0

          [ @value.to_f / @max * 100, 100.0 ].min
        end

        # Calculate ratio (0.0 to 1.0)
        def ratio
          percentage / 100.0
        end

        # Update the max value for this segment
        def max=(new_max)
          raise Error, "Max value must be positive" if new_max <= 0

          @max = new_max
        end

        # Update the color for this segment

        # Update the label for this segment

        # Display name for this segment (label or id)
        def display_name
          @label || @id.to_s.capitalize
        end
      end
    end
  end
end
