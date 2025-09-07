# frozen_string_literal: true

module Unmagic
  module Terminal
    class Grid
      # Represents a cell placed in the grid.
      #
      # Example:
      #
      #   cell = Cell.new(
      #     content: "Hello World",
      #     column: 1,
      #     row: 2,
      #     column_span: 2
      #   )
      class Cell
        attr_reader :content, :column, :row, :column_span, :row_span
        attr_accessor :background, :border, :padding, :align, :justify

        def initialize(content: nil, column: 1, row: 1, column_span: 1, row_span: 1, **options)
          @content = content
          @column = column
          @row = row
          @column_span = column_span
          @row_span = row_span

          # Style options
          @background = options[:background]
          @border = options[:border]
          @padding = options[:padding] || 0
          @align = options[:align] || :start      # :start, :center, :end, :stretch
          @justify = options[:justify] || :start  # :start, :center, :end, :stretch
        end

        # Calculate content width (for auto sizing)
        def content_width
          return 0 unless @content

          if @content.respond_to?(:width)
            @content.width
          elsif @content.is_a?(String)
            # Handle multi-line content
            @content.to_s.split("\n").map(&:length).max || 0
          else
            @content.to_s.length
          end + (@padding * 2) + (border? ? 2 : 0)
        end

        # Calculate content height
        def content_height
          return 1 unless @content

          if @content.respond_to?(:height)
            @content.height
          elsif @content.is_a?(String)
            @content.to_s.split("\n").size
          else
            1
          end + (@padding * 2) + (border? ? 2 : 0)
        end

        # Get content lines
        def content_lines
          return [] unless @content

          if @content.is_a?(String)
            @content.split("\n")
          elsif @content.respond_to?(:to_s)
            @content.to_s.split("\n")
          else
            []
          end
        end

        def border?
          !@border.nil?
        end

        # Calculate ending column
        def end_column
          @column + @column_span - 1
        end

        # Calculate ending row
        def end_row
          @row + @row_span - 1
        end
      end
    end
  end
end
