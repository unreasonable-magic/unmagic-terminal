# frozen_string_literal: true

require_relative "../ansi"
require_relative "../style/background"
require_relative "../style/border"

module Unmagic
  module Terminal
    class Grid
      # Renders a Grid to the terminal.
      # Builds output line by line to handle ANSI codes properly.
      #
      # Example:
      #
      #   renderer = Renderer.new(grid)
      #   renderer.render
      class Renderer
        def initialize(grid, output: $stdout)
          @grid = grid
          @output = output
        end

        # Render the grid to output
        def render
          @output.print to_s
          @output.flush
        end

        # Convert grid to string
        def to_s
          # Calculate all track sizes first
          @grid.calculate_column_sizes
          @grid.calculate_row_sizes

          # Calculate total height
          total_height = calculate_total_height
          return "" if total_height.zero?

          # Build output line by line
          lines = []
          total_height.times do |y|
            line = render_line(y)
            lines << line
          end

          lines.join("\n")
        end

        private

        def calculate_total_height
          return 0 if @grid.row_tracks.empty?

          height = 0
          @grid.row_tracks.each_with_index do |track, i|
            height += track.calculated_size
            height += @grid.row_gap if i < @grid.row_tracks.size - 1
          end
          height
        end

        def render_line(y)
          # Create array for this line's characters
          line_chars = Array.new(@grid.width, " ")

          # Find all items that intersect this line
          @grid.items.each do |item|
            item_y = @grid.row_start(item.row)
            item_height = calculate_item_height(item)

            # Skip if item doesn't intersect this line
            next if y < item_y || y >= item_y + item_height

            # Render this item's portion for this line
            render_item_line(item, y, line_chars)
          end

          line_chars.join
        end

        def render_item_line(item, y, line_chars)
          # Calculate item bounds
          x_start = @grid.column_start(item.column)
          y_start = @grid.row_start(item.row)
          width = calculate_item_width(item)
          height = calculate_item_height(item)

          # Calculate relative y position within item
          rel_y = y - y_start

          # Determine what to render at each x position
          width.times do |rel_x|
            x = x_start + rel_x
            next if x >= @grid.width

            # Determine what goes at this position
            char = nil
            color = nil
            is_background = false

            # Check if it's a border position
            if item.border && is_border_position?(rel_x, rel_y, width, height)
              char = get_border_char(item.border, rel_x, rel_y, width, height)
              color = item.border.color
            # Check for content
            elsif (content_char = get_content_at(item, rel_x, rel_y, width, height))
              char = content_char
            # Otherwise background
            elsif item.background
              char = get_background_char(item.background, rel_x, rel_y)
              color = item.background.color
              is_background = (char == " ")
            end

            # Apply styling and place character
            if char && char != " "
              if color
                styled = style_char(char, color, is_background)
                line_chars[x] = styled
              else
                line_chars[x] = char
              end
            elsif is_background && color
              # Solid background color
              line_chars[x] = style_char(" ", color, true)
            end
          end
        end

        def calculate_item_width(item)
          width = 0
          item.column_span.times do |i|
            width += @grid.column_size(item.column + i)
            width += @grid.column_gap if i < item.column_span - 1
          end
          width
        end

        def calculate_item_height(item)
          height = 0
          item.row_span.times do |i|
            height += @grid.row_size(item.row + i)
            height += @grid.row_gap if i < item.row_span - 1
          end
          height
        end

        def is_border_position?(x, y, width, height)
          return false if width < 2 || height < 2

          y.zero? || y == height - 1 || x.zero? || x == width - 1
        end

        def get_border_char(border, x, y, width, height)
          style = border.style || :single
          chars = Style::Border::STYLES[style] || Style::Border::STYLES[:single]

          if y.zero? # Top row
            if x.zero?
              chars[:top_left]
            elsif x == width - 1
              chars[:top_right]
            else
              chars[:top]
            end
          elsif y == height - 1 # Bottom row
            if x.zero?
              chars[:bottom_left]
            elsif x == width - 1
              chars[:bottom_right]
            else
              chars[:bottom]
            end
          elsif x.zero? # Left edge
            chars[:left]
          elsif x == width - 1 # Right edge
            chars[:right]
          else
            nil
          end
        end

        def get_content_at(item, rel_x, rel_y, width, height)
          return nil unless item.content

          lines = item.content_lines
          padding = item.padding
          border_offset = item.border? ? 1 : 0

          # Calculate content area
          content_x_start = padding + border_offset
          content_y_start = padding + border_offset
          content_width = width - (padding * 2) - (border_offset * 2)
          content_height = height - (padding * 2) - (border_offset * 2)

          # Check if we're in content area
          return nil if rel_x < content_x_start || rel_x >= content_x_start + content_width
          return nil if rel_y < content_y_start || rel_y >= content_y_start + content_height

          # Calculate position within content area
          content_x = rel_x - content_x_start
          content_y = rel_y - content_y_start

          # Apply vertical alignment
          aligned_y = case item.align
          when :center
                        content_y - (content_height - lines.size) / 2
          when :end
                        content_y - (content_height - lines.size)
          else # :start
                        content_y
          end

          # Get the line
          return nil if aligned_y.negative? || aligned_y >= lines.size

          line = lines[aligned_y]

          # Apply horizontal justification
          justified_x = case item.justify
          when :center
                          content_x - (content_width - line.length) / 2
          when :end
                          content_x - (content_width - line.length)
          else # :start
                          content_x
          end

          # Get the character
          return nil if justified_x.negative? || justified_x >= line.length

          line[justified_x]
        end

        def get_background_char(background, x, y)
          pattern = background.pattern

          if pattern == :checkers
            (x + y).even? ? "▚" : "▞"
          elsif pattern
            Style::Background::PATTERNS[pattern] || " "
          else
            background.char || " "
          end
        end

        def style_char(char, color, is_background)
          return char unless color

          if is_background
            # Background color
            if color.is_a?(Array)
              "\e[48;2;#{color[0]};#{color[1]};#{color[2]}m \e[0m"
            elsif color.is_a?(Symbol)
              ANSI.text(" ", background: color)
            else
              char
            end
          elsif color.is_a?(Array)
            # Foreground color
            "\e[38;2;#{color[0]};#{color[1]};#{color[2]}m#{char}\e[0m"
          elsif color.is_a?(Symbol)
            ANSI.text(char, color: color)
          else
            char
          end
        end
      end
    end
  end
end
