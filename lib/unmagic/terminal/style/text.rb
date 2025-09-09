# frozen_string_literal: true

module Unmagic
  module Terminal
    module Style
      # Text style for terminal text. Provides color, style, and alignment options.
      #
      # Example:
      #
      #   text_style = Text.new(color: :blue, style: :bold)
      #   text_style = Text.new(color: [100, 150, 200], style: :italic)  # RGB color
      #   text_style = Text.new(color: :green, align: :center)
      class Text
        STYLES = %i[bold dim italic underline].freeze
        ALIGNMENTS = %i[left center right].freeze

        attr_reader :color, :style, :align

        def initialize(color: nil, style: nil, align: :left)
          @color = color
          @style = style
          @align = align
        end
      end
    end
  end
end