# frozen_string_literal: true

require_relative "grid/track_size"
require_relative "grid/cell"
require_relative "grid/renderer"

module Unmagic
  module Terminal
    # Grid layout system for terminal with proper grid tracks.
    # Supports column templates with fixed, fractional (fr), and auto sizing.
    # Rows automatically grow based on content.
    #
    # Example:
    #
    #   grid = Grid.new(width: 80)
    #   grid.template_columns = "200px 1fr 2fr auto"  # or use array notation
    #   grid.template_columns = [20, :fr, { fr: 2 }, :auto]
    #
    #   grid.add_item(content: "Header", column: 1, column_span: 3)
    #   grid.add_item(content: "Sidebar", column: 1, row: 2)
    #   grid.add_item(content: "Main", column: 2, row: 2, column_span: 2)
    class Grid
      attr_reader :width, :height, :items, :column_tracks, :row_tracks
      attr_accessor :column_gap, :row_gap

      def initialize(width:, height: nil)
        @width = width
        @height = height # Optional, rows can grow beyond this
        @items = []
        @column_tracks = []
        @row_tracks = []
        @column_gap = 1
        @row_gap = 0
      end

      # Set column template using string notation or array
      # Examples:
      #   "100px 1fr 2fr auto"
      #   "20 1fr 1fr 15"
      #   [20, :fr, { fr: 2 }, :auto]
      def template_columns=(template)
        @column_tracks = parse_template(template)
        calculate_column_sizes
      end

      # Add a cell to the grid
      def add_item(content: nil, column: 1, row: nil, column_span: 1, row_span: 1, **options)
        item = Cell.new(
          content: content,
          column: column,
          row: row || next_auto_row,
          column_span: column_span,
          row_span: row_span,
          **options
        )
        @items << item

        # Ensure we have enough row tracks
        ensure_row_tracks(item.row + item.row_span - 1)

        item
      end

      # Calculate actual pixel sizes for columns
      def calculate_column_sizes
        return if @column_tracks.empty?

        # First pass: calculate fixed and auto sizes
        total_fixed = 0
        total_gaps = (@column_tracks.size - 1) * @column_gap
        fr_tracks = []

        @column_tracks.each_with_index do |track, i|
          if track.fixed?
            total_fixed += track.size
          elsif track.auto?
            # For auto, use the maximum content width in that column
            max_width = # Default auto width
              items_in_column(i + 1).map(&:content_width).max || 10
            track.calculated_size = max_width
            total_fixed += max_width
          elsif track.fr?
            fr_tracks << track
          end
        end

        # Second pass: distribute remaining space to fr units
        remaining = @width - total_fixed - total_gaps
        return unless remaining.positive? && fr_tracks.any?

        total_fr = fr_tracks.sum(&:fr_value)
        fr_tracks.each do |track|
          track.calculated_size = (remaining * track.fr_value / total_fr.to_f).floor
        end
      end

      # Calculate actual row sizes based on content
      def calculate_row_sizes
        @row_tracks.each_with_index do |track, row_index|
          # Find all items in this row
          items_in_row = @items.select do |item|
            item.row <= row_index + 1 && item.row + item.row_span > row_index + 1
          end

          # Calculate height based on content
          max_height = items_in_row.map do |item|
            # Height needed for this item in this row
            if item.row_span == 1
              item.content_height
            else
              # For multi-row spans, distribute height
              (item.content_height.to_f / item.row_span).ceil
            end
          end.max || 1

          track.calculated_size = max_height
        end
      end

      # Get the starting column position for a column number
      def column_start(column_number)
        return 0 if column_number <= 1

        position = 0
        (1...column_number).each do |col|
          position += column_size(col) + @column_gap
        end
        position
      end

      # Get the size of a column
      def column_size(column_number)
        track = @column_tracks[column_number - 1]
        track ? track.calculated_size : 0
      end

      # Get the starting row position
      def row_start(row_number)
        return 0 if row_number <= 1

        position = 0
        (1...row_number).each do |row|
          position += row_size(row) + @row_gap
        end
        position
      end

      # Get the size of a row
      def row_size(row_number)
        track = @row_tracks[row_number - 1]
        track ? track.calculated_size : 1
      end

      private

      def parse_template(template)
        if template.is_a?(String)
          # Parse string template like "100px 1fr 2fr auto"
          template.split(/\s+/).map { |part| TrackSize.parse(part) }
        elsif template.is_a?(Array)
          # Parse array template like [20, :fr, { fr: 2 }, :auto]
          template.map { |part| TrackSize.from_value(part) }
        else
          []
        end
      end

      def items_in_column(column_number)
        @items.select do |item|
          item.column <= column_number && item.column + item.column_span > column_number
        end
      end

      def next_auto_row
        return 1 if @items.empty?

        @items.map { |item| item.row + item.row_span - 1 }.max + 1
      end

      def ensure_row_tracks(max_row)
        @row_tracks << TrackSize.new(type: :auto) while @row_tracks.size < max_row
      end
    end
  end
end
