# frozen_string_literal: true

module Unmagic
  module Terminal
    module ASCII
      # LineMerger provides a column-based text layout system for combining multiple
      # ASCII art pieces or text blocks side by side while preserving their original
      # formatting and indentation.
      #
      # ## Overview
      #
      # This class solves the problem of displaying multiple text blocks horizontally
      # adjacent to each other, similar to newspaper columns or terminal multiplexing.
      # It's particularly useful for ASCII art compositions, side-by-side comparisons,
      # or any scenario where you need to present multiple text elements in columns.
      #
      # ## Visual Examples with ASCII Art
      #
      # ### Starting with two ASCII artworks:
      #
      #     duck = <<~ART
      #              __
      #           __( o)>
      #           \\ <_ )
      #            `---'
      #     ART
      #
      #     tree = <<~ART
      #         🌳
      #        /|\\
      #       / | \\
      #        |#|
      #     ART
      #
      # ### Basic merge (default spacing: 2):
      #
      #     merger = Unmagic::ASCII::LineMerger.new
      #     result = merger.merge(duck, tree)
      #
      #     Output:
      #              __    🌳
      #           __( o)>  /|\\
      #           \\ <_ )  / | \\
      #            `---'   |#|
      #
      # ### Merge with increased spacing:
      #
      #     result = merger.merge(duck, tree, spacing: 6)
      #
      #     Output:
      #              __          🌳
      #           __( o)>        /|\\
      #           \\ <_ )        / | \\
      #            `---'         |#|
      #
      # ### Merge with vertical offset (duck moves up):
      #
      #     result = merger.merge(duck, tree, left_offset: 1)
      #
      #     Output:
      #                     🌳
      #              __     /|\\
      #           __( o)>  / | \\
      #           \\ <_ )   |#|
      #            `---'
      #
      # ### Merge with vertical offset (duck moves down):
      #
      #     result = merger.merge(duck, tree, left_offset: -2)
      #
      #     Output:
      #                     🌳
      #                     /|\\
      #              __    / | \\
      #           __( o)>   |#|
      #           \\ <_ )
      #            `---'
      #
      # ## Complex Example: Banner with Duck
      #
      #     banner = <<~ART
      #     ▄▀▀▀▄ █   █ ▄▀▀▀▄ ▄▀▀▀▀ █  ▄▀
      #     █ ▄ █ █   █ █▀▀▀█ █     █▀▀▄
      #      ▀▀▀▄  ▀▀▀  ▀   ▀  ▀▀▀▀ ▀   ▀
      #     ART
      #
      #     # Merge with duck moved up 1 line, spacing of 3
      #     result = merger.merge(duck, banner, spacing: 3, left_offset: 1)
      #
      #     Output:
      #                        ▄▀▀▀▄ █   █ ▄▀▀▀▄ ▄▀▀▀▀ █  ▄▀
      #              __        █ ▄ █ █   █ █▀▀▀█ █     █▀▀▄
      #           __( o)>       ▀▀▀▄  ▀▀▀  ▀   ▀  ▀▀▀▀ ▀   ▀
      #           \\ <_ )
      #            `---'
      #
      # ## Usage with Colors
      #
      #     # Apply gold color to duck, gradient to banner
      #     merger.merge_with_colors(
      #       duck,
      #       banner,
      #       left_color: [255, 215, 0],  # Gold RGB
      #       right_colors: gradient_array, # Per-line colors
      #       spacing: 3,
      #       left_offset: 1
      #     )
      #
      # ## Algorithm
      #
      # The merging algorithm works as follows:
      #
      # 1. **Input Normalization**: Convert input (strings or arrays) into arrays of lines
      #
      # 2. **Vertical Alignment**: Apply vertical offset by prepending empty lines to
      #    either the left or right content:
      #    - Positive offset: moves left content up (right content gets empty lines at top)
      #    - Negative offset: moves left content down (left content gets empty lines at top)
      #
      # 3. **Width Calculation**: Find the maximum width of the left content to ensure
      #    consistent column alignment across all lines
      #
      # 4. **Line-by-line Merging**:
      #    - Pad each left line to the calculated maximum width
      #    - Add spacing between columns
      #    - Append the corresponding right line
      #    - Handle missing lines by using empty strings
      #
      # 5. **Color Application** (optional):
      #    - Apply colors before merging to preserve formatting
      #    - Supports single color for all lines or per-line color arrays
      #    - RGB colors are applied using ANSI escape sequences
      #
      # ## Key Features
      #
      # - **Preserves Indentation**: Original spacing and indentation within each
      #   text block is maintained
      # - **Handles Unequal Heights**: Shorter blocks are automatically padded
      # - **Flexible Input**: Accepts strings, arrays of lines, or mixed inputs
      # - **Color Support**: Full RGB color support with Paint gem integration
      # - **Vertical Positioning**: Adjust relative vertical positions of columns
      #
      class LineMerger
        # Merge two text blocks into columns
        #
        # @param left [String, Array<String>] Left column content
        # @param right [String, Array<String>] Right column content
        # @param spacing [Integer] Number of spaces between columns (default: 2)
        # @param left_offset [Integer] Vertical offset for left content:
        #   - Positive: move left up (right gets empty lines at top)
        #   - Negative: move left down (left gets empty lines at top)
        # @return [Array<String>] Merged lines
        def merge(left, right, spacing: 2, left_offset: 0)
          left_lines = prepare_lines(left)
          right_lines = prepare_lines(right)

          # Apply vertical offset
          if left_offset.negative?
            # Negative offset: move left up = add empty lines to top of right
            right_lines = ([ "" ] * -left_offset) + right_lines
          elsif left_offset.positive?
            # Positive offset: move left down = add empty lines to top of left
            left_lines = ([ "" ] * left_offset) + left_lines
          end

          # Calculate consistent column width
          left_width = left_lines.map(&:length).max || 0

          # Determine total lines needed
          max_lines = [ left_lines.length, right_lines.length ].max

          # Build merged output
          max_lines.times.map do |i|
            left_line = left_lines[i] || ""
            right_line = right_lines[i] || ""

            # Ensure consistent column alignment
            padded_left = left_line.ljust(left_width)

            # Combine with spacing
            padded_left + (" " * spacing) + right_line
          end
        end

        # Merge two text blocks with color support
        #
        # @param left [String, Array<String>] Left column content
        # @param right [String, Array<String>] Right column content
        # @param left_color [Array<Integer>, nil] RGB color for left column [r, g, b]
        # @param right_colors [Array<Integer>, Array<Array<Integer>>, nil]
        #   RGB color(s) for right column:
        #   - Single RGB array: applies to all lines
        #   - Array of RGB arrays: per-line colors (gradient support)
        # @param spacing [Integer] Number of spaces between columns
        # @param left_offset [Integer] Vertical offset for left content
        # @return [Array<String>] Merged lines with ANSI color codes
        def merge_with_colors(left, right, left_color: nil, right_colors: nil,
                              spacing: 2, left_offset: 0)
          left_lines = prepare_lines(left)
          right_lines = prepare_lines(right)

          # Apply vertical offset
          if left_offset.negative?
            # Negative offset: move left up = add empty lines to top of right
            right_lines = ([ "" ] * -left_offset) + right_lines
          elsif left_offset.positive?
            # Positive offset: move left down = add empty lines to top of left
            left_lines = ([ "" ] * left_offset) + left_lines
          end

          # Calculate consistent column width
          left_width = left_lines.map(&:length).max || 0

          # Determine total lines needed
          max_lines = [ left_lines.length, right_lines.length ].max

          # Build merged output with colors
          max_lines.times.map do |i|
            left_line = left_lines[i] || ""
            right_line = right_lines[i] || ""

            # Pad left line for alignment
            padded_left = left_line.ljust(left_width)

            # Apply left color if specified
            colored_left = if left_color
                             Unmagic::Terminal::ANSI.rgb_text(padded_left, left_color)
            else
                             padded_left
            end

            # Apply right color if specified
            colored_right = if right_colors
                              apply_right_color(right_line, right_colors, i)
            else
                              right_line
            end

            # Combine with spacing
            colored_left + (" " * spacing) + colored_right
          end
        end

        private

        # Convert various input formats to array of lines
        def prepare_lines(input)
          case input
          when String
            input.lines(chomp: true)
          when Array
            input
          else
            []
          end
        end

        # Apply color to right column line based on color specification
        def apply_right_color(line, colors, index)
          case colors
          when Array
            if colors.first.is_a?(Array)
              # Array of RGB arrays (gradient or per-line colors)
              color = colors[index] || colors.last
              Unmagic::Terminal::ANSI.rgb_text(line, color)
            else
              # Single RGB array for all lines
              Unmagic::Terminal::ANSI.rgb_text(line, colors)
            end
          when Symbol, String
            # Other color format (symbol, string, etc.)
            Unmagic::Terminal::ANSI.text(line, color: colors)
          else
            line
          end
        end
      end
    end
  end
end
