# frozen_string_literal: true

module Unmagic
  module Terminal
    module ASCII
      module Duck
        def self.art
          <<~DUCK.rstrip
               __
            __( o)>
            \\ <_ )
             `---'
          DUCK
        end
      end
    end
  end
end
