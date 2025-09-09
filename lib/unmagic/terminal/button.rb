# frozen_string_literal: true

require "unmagic/terminal/ansi"
require "unmagic/terminal/style/background"
require "unmagic/terminal/style/border"
require "unmagic/terminal/style/text"

module Unmagic
  module Terminal
    # Interactive button component with state management and styling
    #
    # Example:
    #
    #   button = Button.new(
    #     text: "Click Me",
    #     background: Style::Background.new(color: :blue),
    #     border: Style::Border.new(style: :rounded),
    #     text_style: Style::Text.new(color: :white, style: :bold)
    #   ) do |state|
    #     puts "Button interacted with in #{state} state!"
    #   end
    #
    #   button.render                    # => styled button string
    #   button.interact(:pressed)        # => triggers block callback
    class Button
      STATES = %i[default hover focus pressed].freeze

      attr_reader :text, :state, :background, :border, :text_style

      def initialize(text:, background: nil, border: nil, text_style: nil, &block)
        @text = text
        @state = :default
        @background = background
        @border = border
        @text_style = text_style
        @callback = block
      end

      # Change the button state
      def set_state(new_state)
        raise ArgumentError, "Invalid state: #{new_state}" unless STATES.include?(new_state)

        @state = new_state
      end

      # Interact with the button, triggering the callback if provided
      def interact(interaction_state = nil)
        interaction_state ||= @state
        set_state(interaction_state) if STATES.include?(interaction_state)
        @callback&.call(@state)
      end

      # Render the button as a styled string
      def render
        content = render_text
        content = apply_border(content) if @border
        content
      end

      private

      def render_text
        styled_text = @text

        # Apply text styling if provided
        if @text_style
          styled_text = ANSI.text(
            styled_text,
            color: @text_style.color,
            style: @text_style.style
          )
        end

        # Apply background styling if provided
        if @background
          if @background.color
            styled_text = ANSI.text(
              " #{styled_text} ",
              background: @background.color
            )
          elsif @background.pattern
            char = Style::Background::PATTERNS[@background.pattern] || @background.char
            styled_text = "#{char}#{styled_text}#{char}"
          else
            styled_text = " #{styled_text} "
          end
        else
          styled_text = " #{styled_text} "
        end

        styled_text
      end

      def apply_border(content)
        return content unless @border

        lines = content.split("\n")
        width = lines.map { |line| visible_length(line) }.max
        
        border_chars = Style::Border::STYLES[@border.style] || Style::Border::STYLES[:single]
        
        top_line = border_chars[:top_left] + border_chars[:top] * width + border_chars[:top_right]
        bottom_line = border_chars[:bottom_left] + border_chars[:bottom] * width + border_chars[:bottom_right]
        
        bordered_lines = [top_line]
        lines.each do |line|
          padding = width - visible_length(line)
          bordered_line = border_chars[:left] + line + " " * padding + border_chars[:right]
          bordered_lines << bordered_line
        end
        bordered_lines << bottom_line

        result = bordered_lines.join("\n")
        
        # Apply border color if specified
        if @border.color
          result = ANSI.text(result, color: @border.color)
        end
        
        result
      end

      def visible_length(text)
        # Remove ANSI escape sequences to get actual visible length
        text.gsub(/\e\[[0-9;]*m/, "").length
      end
    end
  end
end