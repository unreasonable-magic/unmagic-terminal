# frozen_string_literal: true

module Unmagic
  module Terminal
    module ASCII
      module Banner
        def self.banner
          <<~STR
            ▄▀▀▀▄ █   █ ▄▀▀▀▄ ▄▀▀▀▀ █  ▄▀ █▀▀▀▄ ▄▀▀▀▄ ▄▀▀▀▀ █  ▄▀
            █ ▄ █ █   █ █▀▀▀█ █     █▀▀▄  █▀▀▀▄ █▀▀▀█ █     █▀▀▄
             ▀▀▀▄  ▀▀▀  ▀   ▀  ▀▀▀▀ ▀   ▀ ▀▀▀▀  ▀   ▀  ▀▀▀▀ ▀   ▀
          STR
        end
      end
    end
  end
end
