# frozen_string_literal: true

module Unmagic
  module Terminal
    class ProgressBar
      # Collection for managing multiple segments in a progress bar.
      # Provides hash-like access with automatic segment creation.
      #
      # Example:
      #
      #   collection = ProgressBar::SegmentCollection.new
      #   collection.define(:download, max: 100, color: :blue)
      #   collection[:download].value = 50
      #   collection[:upload] = 25  # Auto-creates segment with default max=1
      class SegmentCollection
        include Enumerable

        def initialize
          @segments = {}
        end

        # Define a new segment with specific properties
        def define(id, max: 1, color: :green, label: nil)
          raise Error, "Segment #{id} already exists" if @segments.key?(id)

          @segments[id] = Segment.new(
            id: id,
            max: max,
            color: color,
            label: label
          )
        end

        # Get a segment by ID
        def [](id)
          @segments[id] || create_default_segment(id)
        end

        # Set segment value or assign a new segment
        def []=(id, value_or_segment)
          if value_or_segment.is_a?(Segment)
            @segments[id] = value_or_segment
          else
            segment = self[id] # Auto-creates if needed
            segment.value = value_or_segment
          end
        end

        # Check if segment exists
        def key?(id)
          @segments.key?(id)
        end

        # Get all segment IDs
        def keys
          @segments.keys
        end

        # Get all segments
        def values
          @segments.values
        end

        # Iterate over segments
        def each(&block)
          @segments.each(&block)
        end

        # Get segment count
        def size
          @segments.size
        end

        # Check if empty
        def empty?
          @segments.empty?
        end

        # Remove a segment
        def delete(id)
          @segments.delete(id)
        end

        # Clear all segments
        def clear
          @segments.clear
        end

        # Calculate total progress across all segments
        def total_progress
          return 0.0 if @segments.empty?

          total_max = @segments.values.sum(&:max)
          return 0.0 if total_max <= 0

          total_value = @segments.values.sum(&:value)
          (total_value.to_f / total_max * 100).round(1)
        end

        # Get segments ordered by their max values (for proportional rendering)
        def ordered_by_max
          @segments.values.sort_by(&:max).reverse
        end

        private

        # Create a segment with default properties when accessed but not defined
        def create_default_segment(id)
          @segments[id] = Segment.new(
            id: id,
            max: 1,
            color: default_color_for_segment(id),
            label: nil
          )
        end

        # Generate a default color based on segment ID
        def default_color_for_segment(id)
          colors = %i[green blue yellow magenta cyan bright_green bright_blue]
          hash = id.to_s.each_byte.sum
          colors[hash % colors.length]
        end

        class Error < StandardError; end
      end
    end
  end
end
