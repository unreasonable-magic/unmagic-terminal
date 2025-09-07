# frozen_string_literal: true

require_relative "../ansi"
require_relative "../buffer"

module Unmagic
  module Terminal
    class Canvas
      # Handles the actual rendering of regions to the terminal.
      # Optimizes cursor movement and applies styling.
      class Renderer
        def initialize(output)
          @output = output
          @current_x = 0
          @current_y = 0
        end

        # Render a region to the terminal
        def render_region(region)
          render_region_without_flush(region)
          @output.flush
        end

        # Render a region without flushing (for batched rendering)
        def render_region_without_flush(region)
          # Move to region start position
          move_cursor_to(region.x, region.y)

          # Get the final rendered buffer (includes borders if needed)
          buffer = region.render_buffer

          # Render each line of the buffer
          buffer.to_s.split("\n").each_with_index do |line, row|
            move_cursor_to(region.x, region.y + row)
            render_styled_line(line, region.background, region.foreground)
          end
        end

        private

        def render_styled_line(text, bg_color, fg_color)
          # Apply colors if specified
          if bg_color || fg_color
            styled_text = ANSI.text(text, color: fg_color, background: bg_color)
            @output.print styled_text
          else
            @output.print text
          end
        end

        def move_cursor_to(x, y)
          # Always restore to saved origin first, then move relative
          @output.print "\e[u" # Restore to canvas origin
          # Now move relative from the saved position
          @output.print "\e[#{y}B" if y.positive?  # Move down y lines
          @output.print "\e[#{x}C" if x.positive?  # Move right x columns
          @current_x = x
          @current_y = y
        end

        def clear_line
          @output.print "\e[2K"
        end

        def save_cursor
          @output.print "\e[s"
        end

        def restore_cursor
          @output.print "\e[u"
        end
      end
    end
  end
end
