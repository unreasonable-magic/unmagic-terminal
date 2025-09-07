# frozen_string_literal: true

require_relative "generic"
require_relative "kitty/keyboard"

module Unmagic
  module Terminal
    module Emulator
      module Kitty
        # Kitty terminal emulator with enhanced features
        class Kitty < Generic::Generic
          def initialize(input: $stdin, output: $stdout)
            super
            # Replace keyboard with Kitty-enhanced version
            @keyboard = Keyboard.new(input: input, output: output)
            # Mouse can use the generic implementation with SGR mode
          end

          # Kitty supports all the enhanced features
          def supports_enhanced_keyboard?
            true
          end

          def supports_mouse?
            true
          end

          def supports_graphics?
            true
          end

          def supports_true_color?
            true
          end

          def supports_hyperlinks?
            true
          end

          # Enable Kitty keyboard protocol
          def enable_enhanced_features
            @keyboard.enable_enhanced_mode if @keyboard.respond_to?(:enable_enhanced_mode)
            @mouse.enable(mode: :any_event) # Kitty supports all mouse events
          end

          # Disable enhanced features
          def disable_enhanced_features
            @keyboard.disable_enhanced_mode if @keyboard.respond_to?(:disable_enhanced_mode)
            @mouse.disable
          end

          # Display an image using Kitty graphics protocol
          def display_image(path, width: nil, height: nil, preserve_aspect: true)
            require "base64"

            # Read the image file
            image_data = File.binread(path)
            encoded = Base64.strict_encode64(image_data)

            # Build the graphics command
            # a=T means transmit and display
            # f=100 means PNG format (auto-detect would be better)
            command = "a=T,f=100"

            # Add dimensions if specified
            if width || height
              command += ",c=#{width}" if width
              command += ",r=#{height}" if height
            end

            # Send using the graphics protocol
            write "\e_G#{command};#{encoded}\e\\"

            # Add newline for spacing
            write "\n"
          end

          # Create a hyperlink
          def hyperlink(url, text)
            "\e]8;;#{url}\e\\#{text}\e]8;;\e\\"
          end

          # Set terminal title with Kitty's extended format
          def set_title(title, type: :both)
            case type
            when :window
              write "\e]2;#{title}\e\\"
            when :tab
              write "\e]1;#{title}\e\\"
            when :both
              write "\e]0;#{title}\e\\"
            end
          end

          # Kitty-specific: Set tab color
          def set_tab_color(color)
            return unless color.is_a?(Array) && color.length == 3

            r, g, b = color
            write "\e]6;1;bg;rgb;#{r.to_s(16)};#{g.to_s(16)};#{b.to_s(16)}\e\\"
          end

          # Kitty-specific: Send notification
          def notify(title, body = nil, urgency: :normal)
            notification = "\e]99;i=notify;"
            notification += "t=#{title};"
            notification += "b=#{body};" if body
            notification += "u=#{urgency};"
            notification += "\e\\"
            write notification
          end

          # Kitty-specific: Copy to clipboard
          def copy_to_clipboard(text, clipboard: :clipboard)
            encoded = Base64.strict_encode64(text)
            type = clipboard == :primary ? "p" : "c"
            write "\e]52;#{type};#{encoded}\e\\"
          end

          # Kitty-specific: Request clipboard contents
          def paste_from_clipboard(clipboard: :clipboard)
            type = clipboard == :primary ? "p" : "c"
            write "\e]52;#{type};?\e\\"
            # Would need to parse the response
          end
        end
      end
    end
  end
end
