# frozen_string_literal: true

module Unmagic
  module Terminal
    module ASCII
      # Layout provides a virtual grid system for composing ASCII art and text
      # in a flexible, progressive manner. Think of it as a canvas where you can
      # place text elements at specific positions or flow them naturally.
      #
      # ## Overview
      #
      # Layout treats your terminal as a 2D grid where you can:
      # - Append text/art to flow naturally left-to-right
      # - Position elements at specific coordinates
      # - Apply colors and styles to individual elements
      # - Build complex compositions incrementally
      #
      # ## Basic Usage
      #
      #     layout = Unmagic::ASCII::Layout.new
      #
      #     # Simple append - flows left to right
      #     layout << "Hello"
      #     layout << "World"
      #
      #     # With positioning
      #     layout << { text: duck_art, offset: [10, 2] }  # 10 right, 2 down
      #
      #     # With color
      #     layout << { text: "RED", color: [255, 0, 0] }
      #
      #     # Render to see the result
      #     puts layout.render
      #
      # ## Understanding the Cursor Flow
      #
      #     layout = Unmagic::ASCII::Layout.new
      #
      #     layout << "A"    # Cursor starts at (0,0), moves to (3,0) after
      #     layout << "B"    # Placed at (3,0), cursor moves to (6,0)
      #     layout << "C"    # Placed at (6,0), cursor moves to (9,0)
      #
      #     Output (with cursor positions):
      #     ┌─────────┐
      #     │A  B  C  │
      #     └─────────┘
      #      ↑  ↑  ↑
      #     0,0 3,0 6,0
      #
      #     # Default spacing of 2 spaces between elements
      #     # Cursor auto-advances after each append
      #
      # ## Visual Examples
      #
      # ### Building a simple composition:
      #
      #     layout = Unmagic::ASCII::Layout.new
      #
      #     # Add a duck (note the leading spaces for alignment)
      #     duck = <<~ART
      #              __
      #           __( o)>
      #           \\ <_ )
      #            `---'
      #     ART
      #
      #     layout << duck
      #
      #     # Add a cat next to it
      #     cat = <<~ART
      #      /\\_/\\
      #     ( o.o )
      #      > ^ <
      #     ART
      #
      #     layout << cat
      #
      #     Output (grid visualization):
      #     ┌────────────────────────┐
      #     │         __       /\\_/\\ │ Row 0
      #     │      __( o)>    ( o.o )│ Row 1
      #     │      \\ <_ )      > ^ < │ Row 2
      #     │       `---'            │ Row 3
      #     └────────────────────────┘
      #     0,0 ─────────────────> X
      #
      # ### Using offsets for positioning:
      #
      #     layout = Unmagic::ASCII::Layout.build do |grid|
      #       grid << duck
      #       grid << { text: cat, offset: { lines: -1, cols: 2 } }  # Up 1 line, right 2 cols
      #     end
      #
      #     Output (grid visualization):
      #     ┌───────────────────────┐
      #     │                 /\\_/\\ │ Row 0 (cat moved up 1)
      #     │         __     ( o.o )│ Row 1
      #     │      __( o)>    > ^ < │ Row 2
      #     │      \\ <_ )           │ Row 3
      #     │       `---'           │ Row 4
      #     └───────────────────────┘
      #     0,0 ─────────────────> X
      #         ↑duck  ↑cat (+2 spacing, -1 vertical)
      #
      # ### Absolute positioning:
      #
      #     layout = Unmagic::ASCII::Layout.new
      #     layout << { text: "A", position: [0, 0] }
      #     layout << { text: "B", position: [10, 0] }
      #     layout << { text: "C", position: [5, 2] }
      #
      #     Output (grid visualization):
      #     ┌────────────┐
      #     │A         B │ Row 0
      #     │            │ Row 1
      #     │     C      │ Row 2
      #     └────────────┘
      #      ↑    ↑    ↑
      #     0,0  5,2  10,0
      #
      #     Grid coordinates:
      #     • (0,0) = top-left corner
      #     • X increases rightward →
      #     • Y increases downward ↓
      #
      # ### Building a complex scene:
      #
      #     layout = Unmagic::ASCII::Layout.new
      #
      #     # Add banner at top
      #     banner = "QUACKBACK"
      #     layout << { text: banner, position: [5, 0] }
      #
      #     # Add duck below (starts at column 2, row 2)
      #     layout << { text: duck, position: [2, 2] }
      #
      #     # Add cat to the right (starts at column 20, row 3)
      #     layout << { text: cat, position: [20, 3] }
      #
      #     Output (grid visualization):
      #     ┌────────────────────────────┐
      #     │     QUACKBACK              │ Row 0
      #     │                            │ Row 1
      #     │           __               │ Row 2
      #     │        __( o)>      /\\_/\\  │ Row 3
      #     │        \\ <_ )      ( o.o ) │ Row 4
      #     │         `---'       > ^ <  │ Row 5
      #     │                            │ Row 6
      #     └────────────────────────────┘
      #      0    5    10   15   20    25
      #      ↑    ↑              ↑
      #     0,0  banner(5,0)   cat(20,3)
      #          ↑
      #        duck(2,2)
      #
      # ## API Options
      #
      # When using `<<`, you can pass either:
      #
      # 1. **String/text directly**: Appends at current cursor position
      #
      #        layout << "Hello"
      #
      # 2. **Hash with options**:
      #    - `text`: The content to add (required)
      #    - `offset`: Hash with positioning keys or [x, y] array (optional)
      #      - `lines`: Positive = move down, negative = move up
      #      - `cols`/`columns`: Positive = move right, negative = move left
      #    - `position`: [x, y] absolute position on grid (optional)
      #    - `color`: RGB array [r, g, b] or color symbol (optional)
      #    - `spacing`: Extra spacing before this element (optional)
      #
      #        grid << {
      #          text: "Hello",
      #          offset: { lines: -2, cols: 10 },  # Up 2 lines, right 10 columns
      #          color: [255, 0, 0]
      #        }
      #
      class Layout
        attr_reader :grid, :cursor_x, :cursor_y, :max_x, :max_y

        def self.build
          layout = new
          yield layout if block_given?
          layout
        end

        def initialize(width: nil, height: nil)
          @grid = {} # Sparse grid storage
          @cursor_x = 0
          @cursor_y = 0
          @max_x = 0
          @max_y = 0
          @width = width
          @height = height
          @default_spacing = 2
        end

        # Main method for adding content to the layout
        def <<(content)
          case content
          when String
            add_text(content)
          when Hash
            add_with_options(content)
          else
            raise ArgumentError, "Expected String or Hash, got #{content.class}"
          end
          self
        end

        # Move cursor to next line
        def newline(count = 1)
          @cursor_y += count
          @cursor_x = 0
          self
        end

        # Set cursor position
        def move_to(x, y)
          @cursor_x = x
          @cursor_y = y
          self
        end

        # Render the layout to an array of strings
        def render
          return [] if @grid.empty?

          # Find bounds
          min_x = @grid.keys.map(&:first).min
          min_y = @grid.keys.map(&:last).min
          max_x = @grid.keys.map(&:first).max
          max_y = @grid.keys.map(&:last).max

          # Normalize to start at 0,0
          normalized_grid = {}
          @grid.each do |(x, y), cell|
            normalized_grid[[ x - min_x, y - min_y ]] = cell
          end

          # Calculate dimensions
          width = max_x - min_x + 1
          height = max_y - min_y + 1

          # Build output lines
          lines = []
          (0...height).each do |y|
            line = ""
            (0...width).each do |x|
              cell = normalized_grid[[ x, y ]]
              line += if cell
                        if cell[:color]
                          apply_color(cell[:char], cell[:color])
                        else
                          cell[:char]
                        end
              else
                        " "
              end
            end
            lines << line.rstrip # Remove trailing spaces
          end

          # Remove trailing empty lines
          lines.pop while lines.last && lines.last.empty?

          lines
        end

        # Render as a single string
        def to_s
          render.join("\n")
        end

        private

        def add_text(text, x: @cursor_x, y: @cursor_y, color: nil)
          lines = text.is_a?(Array) ? text : text.to_s.lines(chomp: true)

          lines.each_with_index do |line, line_idx|
            # Determine color for this line
            line_color = if color.is_a?(Array) && color.first.is_a?(Array)
                           # Array of colors (gradient) - use per-line color
                           color[line_idx] || color.last
            else
                           # Single color for all lines
                           color
            end

            line.chars.each_with_index do |char, char_idx|
              pos_x = x + char_idx
              pos_y = y + line_idx

              @grid[[ pos_x, pos_y ]] = { char: char, color: line_color }

              @max_x = pos_x if pos_x > @max_x
              @max_y = pos_y if pos_y > @max_y
            end
          end

          # Update cursor to end of text
          return unless lines.any?

          last_line = lines.last
          @cursor_x = x + last_line.length + @default_spacing
          @cursor_y = y
        end

        def add_with_options(options)
          # Validate allowed keys
          allowed_keys = %i[text offset position color spacing]
          unknown_keys = options.keys - allowed_keys

          unless unknown_keys.empty?
            raise ArgumentError,
                  "Unknown options: #{unknown_keys.join(', ')}. Allowed options are: #{allowed_keys.join(', ')}"
          end

          text = options[:text] || raise(ArgumentError, "Hash must include :text")

          if options[:position]
            # Absolute positioning
            x, y = options[:position]
          else
            # Calculate offsets from offset hash
            offset_x = 0
            offset_y = 0

            if options[:offset]
              offset_hash = options[:offset]

              # Validate offset keys
              if offset_hash.is_a?(Hash)
                allowed_offset_keys = %i[lines cols columns]
                unknown_offset_keys = offset_hash.keys - allowed_offset_keys

                unless unknown_offset_keys.empty?
                  raise ArgumentError,
                        "Unknown offset options: #{unknown_offset_keys.join(', ')}. Allowed offset options are: #{allowed_offset_keys.join(', ')}"
                end

                # lines: positive = move down, negative = move up
                # cols/columns: positive = move right, negative = move left
                offset_y += offset_hash[:lines] if offset_hash[:lines]
                offset_x += offset_hash[:cols] if offset_hash[:cols]
                offset_x += offset_hash[:columns] if offset_hash[:columns] # Alias for cols
              elsif offset_hash.is_a?(Array)
                # Legacy [x, y] support
                offset_x += offset_hash[0]
                offset_y += offset_hash[1]
              else
                raise ArgumentError, "offset must be a Hash or Array"
              end
            end

            spacing = options[:spacing] || 0

            x = @cursor_x + offset_x + spacing
            y = @cursor_y + offset_y

          end
          add_text(text, x: x, y: y, color: options[:color])
        end

        def apply_color(text, color)
          case color
          when Array
            if color.first.is_a?(Array)
              # Array of colors (for gradients) - just use first for now
              Unmagic::Terminal::ANSI.rgb_text(text, color.first)
            else
              # Single RGB color
              Unmagic::Terminal::ANSI.rgb_text(text, color)
            end
          when Symbol, String
            Unmagic::Terminal::ANSI.text(text, color: color)
          else
            text
          end
        end
      end
    end
  end
end
