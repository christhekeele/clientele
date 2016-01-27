require 'clientele/utils/configuration/conversion'

module Clientele
  module Utils
    class Configuration
      module Identity

        def hash
          as_hash.hash
        end

        def empty?
          instance_variables.empty?
        end

      end
    end
  end
end
