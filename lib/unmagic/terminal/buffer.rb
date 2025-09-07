# frozen_string_literal: true

module Unmagic
  module Terminal
    # Buffer for composing terminal content with proper positioning.
    # Handles a 2D array of strings that can be rendered to the terminal.
    # Automatically calculates dimensions from string content, handling emojis
    # and wide characters that take up 2 columns.
    #
    # Example:
    #
    #   buffer = Buffer.new(value: "Hello\nWorld")
    #   buffer.width   #=> 5
    #   buffer.height  #=> 2
    #   buffer.to_s    #=> "Hello\nWorld"
    #
    #   # With fixed dimensions (truncates/pads as needed)
    #   buffer = Buffer.new(value: "Hello World", width: 8, height: 1)
    #   buffer.to_s    #=> "Hello Wo"
    #
    #   # Merging buffers
    #   b1 = Buffer.new(value: "AAA")
    #   b2 = Buffer.new(value: "BBB")
    #   result = b1.merge(b2, at: :below)  # or use b1 << b2
    #   result.to_s  #=> "AAA\nBBB"
    class Buffer
      attr_reader :width, :height

      def initialize(value:, width: nil, height: nil)
        @value = value.to_s
        lines = @value.split("\n", -1)

        # Calculate dimensions
        if width && height
          # Use provided dimensions
          @width = width
          @height = height
        elsif width
          # Width provided, calculate height
          @width = width
          @height = lines.size
        elsif height
          # Height provided, calculate width
          @height = height
          @width = lines.map { |line| display_width(line) }.max || 0
        else
          # Calculate both from content
          @height = lines.empty? ? 0 : lines.size
          @width = lines.map { |line| display_width(line) }.max || 0
        end

        # Initialize the buffer grid
        @lines = Array.new(@height) { Array.new(@width, " ") }

        # Populate the buffer with the content (truncate/pad as needed)
        lines.take(@height).each_with_index do |line, y|
          x = 0
          line.each_char do |char|
            char_w = char_width(char)

            # Skip if we'd go past the width
            break if x + char_w > @width

            # Place the character
            @lines[y][x] = char

            # For wide chars, fill next cell with nil as placeholder
            @lines[y][x + 1] = nil if char_w == 2 && x + 1 < @width

            x += char_w
          end
        end
      end

      # Merge another buffer with this one
      # at: :below  - append to bottom (vertical stack)
      # at: :above  - prepend to top (vertical stack)
      # at: :right  - append to right (horizontal join)
      # at: :left   - prepend to left (horizontal join)
      # at: [x, y]  - overlay at specific position
      def merge(other, at: :below)
        case at
        when :below
          merge_below(other)
        when :above
          merge_above(other)
        when :right
          merge_right(other)
        when :left
          merge_left(other)
        when Array
          raise ArgumentError, "Position must be [x, y] array" unless at.size == 2

          merge_at_position(other, at[0], at[1])
        else
          raise ArgumentError, "Invalid merge position: #{at}"
        end
      end

      # Append operator - same as merge(other, at: :below)
      def <<(other)
        merge(other, at: :below)
      end

      # Convert buffer to string for terminal output
      def to_s
        @lines.map do |line|
          # Convert line to string, handling nil placeholders for wide chars
          result = String.new
          line.each do |char|
            result << char unless char.nil?
          end
          result
        end.join("\n")
      end

      protected

      # Internal helper to get character at position
      def get_char(x, y)
        return nil if x.negative? || x >= @width || y.negative? || y >= @height

        @lines[y][x]
      end

      # Internal helper to set character at position
      def set_char(x, y, char)
        return if x.negative? || x >= @width || y.negative? || y >= @height

        @lines[y][x] = char
      end

      private

      def merge_below(other)
        # Stack vertically - new buffer has combined height, max width
        new_width = [ @width, other.width ].max
        new_height = @height + other.height

        result = Buffer.new(value: "", width: new_width, height: new_height)

        # Copy self to top
        @height.times do |y|
          @width.times do |x|
            char = @lines[y][x]
            result.set_char(x, y, char) unless char.nil?
          end
        end

        # Copy other below
        other.height.times do |y|
          other.width.times do |x|
            char = other.get_char(x, y)
            result.set_char(x, @height + y, char) unless char.nil?
          end
        end

        result
      end

      def merge_above(other)
        # Stack vertically with other on top
        other.merge(self, at: :below)
      end

      def merge_right(other)
        # Join horizontally - new buffer has combined width, max height
        new_width = @width + other.width
        new_height = [ @height, other.height ].max

        result = Buffer.new(value: "", width: new_width, height: new_height)

        # Copy self to left
        @height.times do |y|
          @width.times do |x|
            char = @lines[y][x]
            result.set_char(x, y, char) unless char.nil?
          end
        end

        # Copy other to right
        other.height.times do |y|
          other.width.times do |x|
            char = other.get_char(x, y)
            result.set_char(@width + x, y, char) unless char.nil?
          end
        end

        result
      end

      def merge_left(other)
        # Join horizontally with other on left
        other.merge(self, at: :right)
      end

      def merge_at_position(other, pos_x, pos_y)
        # Overlay at specific position
        # Calculate dimensions to fit both buffers
        new_width = [ width, pos_x + other.width ].max
        new_height = [ height, pos_y + other.height ].max

        result = Buffer.new(value: "", width: new_width, height: new_height)

        # Copy self first
        @height.times do |y|
          @width.times do |x|
            char = @lines[y][x]
            result.set_char(x, y, char) unless char.nil?
          end
        end

        # Overlay other at position (non-space chars overwrite)
        other.height.times do |y|
          other.width.times do |x|
            char = other.get_char(x, y)
            result.set_char(pos_x + x, pos_y + y, char) if char && char != " "
          end
        end

        result
      end

      # Calculate display width of a string (handles emojis and wide chars)
      def display_width(str)
        return 0 if str.nil? || str.empty?

        width = 0
        str.each_char do |char|
          width += char_width(char)
        end
        width
      end

      # Get the display width of a single character
      def char_width(char)
        code = char.ord

        # Control characters
        return 0 if code < 0x20 || (code >= 0x7F && code <= 0x9F)

        # Emoji ranges (simplified - covers most common emojis)
        return 2 if emoji?(char)

        # CJK characters
        return 2 if cjk?(char)

        # Default to 1 for ASCII and most Latin characters
        1
      end

      def emoji?(char)
        code = char.ord

        # ASCII printable characters (including digits) are never emojis
        return false if code >= 0x20 && code <= 0x7E

        # Common emoji ranges
        case code
        when 0x1F300..0x1F9FF # Emoticons, symbols, etc.
          true
        when 0x2600..0x27BF     # Miscellaneous symbols
          true
        when 0x1F000..0x1F02F   # Mahjong & dominoes
          true
        when 0x1FA70..0x1FAFF   # Extended symbols
          true
        when 0x2700..0x27BF     # Dingbats
          true
        else
          # Check for emoji modifiers and combining characters
          char.match?(/\p{Emoji}/)
        end
      rescue StandardError
        false
      end

      def cjk?(char)
        code = char.ord

        # CJK Unified Ideographs
        (code >= 0x4E00 && code <= 0x9FFF) ||
          # CJK Compatibility
          (code >= 0xF900 && code <= 0xFAFF) ||
          # Hiragana & Katakana
          (code >= 0x3040 && code <= 0x30FF) ||
          # Hangul
          (code >= 0xAC00 && code <= 0xD7AF) ||
          # Full-width ASCII
          (code >= 0xFF01 && code <= 0xFF60)
      end
    end
  end
end
