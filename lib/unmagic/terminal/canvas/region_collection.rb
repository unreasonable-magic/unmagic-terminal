# frozen_string_literal: true

module Unmagic
  module Terminal
    class Canvas
      # Hash-like interface for managing canvas regions.
      # Provides convenient operators for updating region content.
      #
      # Example:
      #
      #   canvas.regions[:status] = "Ready"        # Replace content
      #   canvas.regions[:logs] << "New line\n"    # Append content
      #   canvas.regions.clear(:logs)              # Clear a region
      class RegionCollection
        def initialize(canvas)
          @canvas = canvas
        end

        # Get current content of a region
        def [](key)
          region = @canvas.get_region(key)
          region&.content
        end

        # Replace content of a region
        def []=(key, value)
          unless @canvas.has_region?(key)
            raise ArgumentError, "Region #{key} not defined. Use canvas.define_region first"
          end

          @canvas.send_message(:update, key, value.to_s)
        end

        # Return a proxy for append operations
        # This allows: canvas.regions[:logs] << "text"
        def [](key)
          raise ArgumentError, "Region #{key} not defined" unless @canvas.has_region?(key)

          AppendProxy.new(@canvas, key)
        end

        # Clear a region's content
        def clear(key)
          raise ArgumentError, "Region #{key} not defined" unless @canvas.has_region?(key)

          @canvas.send_message(:clear, key)
          nil
        end

        # Delete a region entirely
        def delete(key)
          raise ArgumentError, "Region #{key} not defined" unless @canvas.has_region?(key)

          # First clear it visually
          @canvas.send_message(:clear, key)

          # Then remove from canvas
          @canvas.instance_eval do
            @mutex.synchronize { @regions_map.delete(key) }
          end

          nil
        end

        # Check if a region exists
        def key?(key)
          @canvas.has_region?(key)
        end

        alias has_key? key?
        alias include? key?

        # Get all region names
        def keys
          @canvas.instance_eval do
            @mutex.synchronize { @regions_map.keys }
          end
        end

        # Proxy object to handle append operations
        class AppendProxy
          def initialize(canvas, key)
            @canvas = canvas
            @key = key
          end

          # Append content to the region
          def <<(value)
            @canvas.send_message(:append, @key, value.to_s)
            self # Return self for chaining
          end

          # Also support getting the current content
          def to_s
            region = @canvas.get_region(@key)
            region&.content || ""
          end
        end
      end
    end
  end
end
