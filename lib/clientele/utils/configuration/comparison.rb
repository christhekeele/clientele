require 'clientele/utils/configuration/conversion'

module Clientele
  module Utils
    class Configuration
      module Comparison

        # Compare values only, class doesn't matter
        def == other
          if other.respond_to?(:to_hash)
            to_hash == other.to_hash
          end
        end

        # Compare values only, class matters
        def eql?(other)
          if other.respond_to?(:to_hash)
            as_hash == other.to_hash
          end
        end

        # Compare classes or instances for case statements
        def === other
          unless other.is_a? Class
            to_hash(false) == other.to_hash if other.respond_to? :to_hash
          else
            super
          end
        end

      end
    end
  end
end
