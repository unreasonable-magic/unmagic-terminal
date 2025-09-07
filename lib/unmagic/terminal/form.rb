# frozen_string_literal: true

module Unmagic
  module Terminal
    # Terminal form components for interactive UIs
    module Form
      # Base class for form components
      class Component
        attr_reader :terminal

        def initialize(terminal: Terminal.current)
          @terminal = terminal
        end
      end
    end
  end
end
