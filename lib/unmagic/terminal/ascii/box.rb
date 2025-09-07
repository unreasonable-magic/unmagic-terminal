# frozen_string_literal: true

# Create Unicode boxes with rounded corners for terminal display.
# Provides a simple API for wrapping text content in decorative boxes.
#
# Example:
#
#   # Simple box
#   box = Unmagic::Terminal::ASCII::Box.new("Hello World")
#   puts box.render
#
#   # Box with title
#   box = Unmagic::ASCII::Box.new("Content goes here", title: "My Box")
#   puts box.render
#
#   # Box with custom width and padding
#   box = Unmagic::ASCII::Box.new("Centered text", width: 40, padding: 2, alignment: :center)
#   puts box.render

module Unmagic
  module Terminal
    module ASCII
      class Box
        attr_reader :content, :options

        def initialize(content, **options)
          @content = content.to_s
          @options = {
            padding: 1,
            alignment: :left,
            width: nil,
            title: nil,
            style: :rounded,
            color: nil,
            title_color: nil
          }.merge(options)
        end

        def render
          lines = prepare_content_lines
          box_width = calculate_box_width(lines)

          output = []
          output << draw_top_border(box_width)

          # Add padding lines at top
          options[:padding].times do
            output << draw_content_line("", box_width)
          end

          # Add content lines
          lines.each do |line|
            output << draw_content_line(line, box_width)
          end

          # Add padding lines at bottom
          options[:padding].times do
            output << draw_content_line("", box_width)
          end

          output << draw_bottom_border(box_width)

          # Apply color if specified
          result = output.join("\n")
          if options[:color]
            require_relative "../color" unless defined?(Color)
            result = Unmagic::Terminal::ANSI.text(result, color: options[:color]) if defined?(Color)
          end

          result
        end

        def to_s
          render
        end

        private

        def prepare_content_lines
          # Split content into lines, handling existing newlines
          content.split("\n")
        end

        def calculate_box_width(lines)
          if options[:width]
            # Use specified width, ensuring it's not smaller than longest line
            min_width = lines.map { |line| strip_ansi(line).length }.max || 0
            min_width += (options[:padding] * 2)
            [ options[:width], min_width ].max
          else
            # Calculate width based on content
            max_line_length = lines.map { |line| strip_ansi(line).length }.max || 0
            max_line_length + (options[:padding] * 2)
          end
        end

        def strip_ansi(text)
          # Remove ANSI color codes for accurate length calculation
          text.gsub(/\e\[[\d;]*m/, "")
        end

        def get_border_chars
          case options[:style]
          when :rounded
            {
              top_left: "╭",
              top_right: "╮",
              bottom_left: "╰",
              bottom_right: "╯",
              horizontal: "─",
              vertical: "│",
              title_left: "┤",
              title_right: "├"
            }
          when :square
            {
              top_left: "┌",
              top_right: "┐",
              bottom_left: "└",
              bottom_right: "┘",
              horizontal: "─",
              vertical: "│",
              title_left: "┤",
              title_right: "├"
            }
          when :double
            {
              top_left: "╔",
              top_right: "╗",
              bottom_left: "╚",
              bottom_right: "╝",
              horizontal: "═",
              vertical: "║",
              title_left: "╡",
              title_right: "╞"
            }
          when :ascii
            {
              top_left: "+",
              top_right: "+",
              bottom_left: "+",
              bottom_right: "+",
              horizontal: "-",
              vertical: "|",
              title_left: "|",
              title_right: "|"
            }
          else
            get_border_chars_for(:rounded)
          end
        end

        def draw_top_border(width)
          chars = get_border_chars

          if options[:title]
            title = " #{options[:title]} "
            title_length = strip_ansi(title).length

            # Apply title color if specified
            if options[:title_color] && defined?(Color)
              require_relative "../color" unless defined?(Color)
              title = Unmagic::Terminal::ANSI.text(title, color: options[:title_color])
            end

            # Calculate padding for title
            remaining = width - title_length - 2 # -2 for the title brackets
            left_padding = 2 # Small padding before title
            right_padding = remaining - left_padding

            # Ensure we don't have negative padding
            if remaining < 4 # Need at least some padding
              # Title is too long, truncate it
              max_title_length = [ width - 8, 1 ].max # Leave room for borders and minimal padding
              truncated_title = options[:title][0...max_title_length]
              title = truncated_title.length.positive? ? " #{truncated_title}... " : " ... "
              title_length = strip_ansi(title).length
              remaining = width - title_length - 2
              left_padding = [ remaining / 2, 1 ].max
              right_padding = [ remaining - left_padding, 1 ].max
            end

            chars[:top_left] +
              (chars[:horizontal] * left_padding) +
              chars[:title_left] +
              title +
              chars[:title_right] +
              (chars[:horizontal] * right_padding) +
              chars[:top_right]
          else
            chars[:top_left] + (chars[:horizontal] * width) + chars[:top_right]
          end
        end

        def draw_bottom_border(width)
          chars = get_border_chars
          chars[:bottom_left] + (chars[:horizontal] * width) + chars[:bottom_right]
        end

        def draw_content_line(text, width)
          chars = get_border_chars
          text_length = strip_ansi(text).length
          available_width = width - (options[:padding] * 2)

          # Truncate if text is too long
          if text_length > available_width
            text = text[0...available_width]
            available_width
          end

          # Apply alignment
          aligned_text = align_text(text, available_width)

          # Add padding
          padding = " " * options[:padding]

          chars[:vertical] + padding + aligned_text + padding + chars[:vertical]
        end

        def align_text(text, width)
          text_length = strip_ansi(text).length
          padding_needed = width - text_length

          case options[:alignment]
          when :right
            " " * padding_needed + text
          when :center
            left_pad = padding_needed / 2
            right_pad = padding_needed - left_pad
            " " * left_pad + text + " " * right_pad
          else # :left
            text + " " * padding_needed
          end
        end

        # Convenience class methods
        def self.generate(content, **options)
          new(content, **options).render
        end

        # Create a simple ASCII box (no unicode)
        def self.ascii(content, **options)
          generate(content, **options.merge(style: :ascii))
        end

        # Create a box with double-line borders
        def self.double(content, **options)
          generate(content, **options.merge(style: :double))
        end

        # Create a box with square corners (single-line)
        def self.square(content, **options)
          generate(content, **options.merge(style: :square))
        end
      end
    end
  end
end
