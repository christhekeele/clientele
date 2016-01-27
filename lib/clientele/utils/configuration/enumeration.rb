require 'clientele/utils/configuration/conversion'

module Clientele
  module Utils
    class Configuration
      module Enumeration

        include Enumerable
        def each(*args, &block)
          to_hash.each(*args, &block)
        end

      end
    end
  end
end
