# frozen_string_literal: true

require_relative "../buffer"

module Unmagic
  module Terminal
    class Canvas
      # Internal representation of a canvas region using Terminal Buffer.
      # Each region IS a buffer with positioning and styling information.
      class Region
        attr_reader :id, :x, :y, :width, :height

        def initialize(id:, x:, y:, width:, height:, bg: nil, fg: nil, border: false)
          @id = id
          @x = x
          @y = y
          @width = width
          @height = height
          @bg = bg
          @fg = fg
          @border = border

          # Calculate effective dimensions for content
          content_width = @border ? @width - 2 : @width
          content_height = @border ? @height - 2 : @height

          # Initialize content buffer
          @content_buffer = Buffer.new(value: "", width: content_width, height: content_height)

          # Keep track of all content for scrolling
          @all_content = ""
        end

        # Background color for the region
        def background
          @bg
        end

        # Foreground color for the region
        def foreground
          @fg
        end

        # Whether to draw a border
        def border?
          @border
        end

        # Replace content entirely
        def content=(new_content)
          @all_content = new_content.to_s
          rebuild_content_buffer
        end

        # Get current content
        def content
          @all_content
        end

        # Append content (with automatic scrolling)
        def append_content(additional_content)
          @all_content += additional_content.to_s
          rebuild_content_buffer
        end

        # Clear all content
        def clear
          @all_content = ""
          rebuild_content_buffer
        end

        # Get the final rendered buffer (content + borders if needed)
        def render_buffer
          if @border
            create_bordered_buffer
          else
            @content_buffer
          end
        end

        # Get just the content buffer (for renderer compatibility)
        attr_reader :content_buffer

        private

        # Rebuild the content buffer with auto-scrolling
        def rebuild_content_buffer
          content_width = @border ? @width - 2 : @width
          content_height = @border ? @height - 2 : @height

          # For scrolling behavior, we want to show the last N lines of content
          lines = @all_content.split(/\n/, -1)

          # Remove trailing empty line if content doesn't end with newline
          lines.pop if lines.last == "" && !@all_content.end_with?("\n")

          # Auto-scroll: take the last content_height lines
          visible_lines = if lines.length <= content_height
                            lines
          else
                            lines[-content_height..] || []
          end

          # Join back into content for the buffer
          visible_content = visible_lines.join("\n")

          # Create new buffer with proper dimensions
          @content_buffer = Buffer.new(
            value: visible_content,
            width: content_width,
            height: content_height
          )
        end

        # Create a bordered buffer by merging content with border
        def create_bordered_buffer
          # Create border components
          top_border = "┌#{'─' * (@width - 2)}┐"
          bottom_border = "└#{'─' * (@width - 2)}┘"

          # Create border buffers
          top_buffer = Buffer.new(value: top_border, width: @width, height: 1)
          bottom_buffer = Buffer.new(value: bottom_border, width: @width, height: 1)

          # Create side borders for content area
          content_with_borders = @content_buffer.to_s.split("\n").map do |line|
            "│#{line}│"
          end.join("\n")

          # Create middle section buffer
          middle_buffer = Buffer.new(value: content_with_borders, width: @width, height: @height - 2)

          # Combine all parts
          top_buffer.merge(middle_buffer, at: :below).merge(bottom_buffer, at: :below)
        end
      end
    end
  end
end
