require "clientele/utils/extensions/hash"

module Clientele
  module Utils
    class Configuration
      module Conversion

        def self.included(root)
          root.extend ClassMethods
        end

        module ClassMethods

          def from_hash(source={})
            initialize_from_hash source
          end
          alias_method :[], :from_hash

          def load(source)
            initialize_from_hash (JSON.load(source) or {})
          end

          def dump(configuration)
            configuration.dump if configuration
          end

        protected

          def initialize_from_hash(source)
            klass = if klass_name = source.delete(:__configuration_class__)
              Object.const_get klass_name
            else; self; end

            klass.new.load_hash source
          end

        end

        def load_hash(source={})
          source.each do |key, value|
            if value.is_a? Hash
              send :"#{key}=", self.class.from_hash(value)
            else
              send :"#{key}=", value
            end
          end
          self
        end

        def to_hash
          hash_representation.keep_if do |key|
            settings.include? key
          end
        end

        def dump
          to_hash.to_json.to_s
        end

        def to_s
          to_hash.inspect.to_s
        end

      # protected

        def as_hash
          @__hash_representation__ ||= hash_representation
        end

        def hash_representation
          unless empty?
            Hash[
              instance_variables.map do |instance_variable_name|
                key = instance_variable_name.to_s.gsub('@', '').to_sym
                value = instance_variable_get(instance_variable_name)
                value = value.hash_representation if value.is_a?(Configuration)
                [key, value]
              end
            ]
          else
            {}
          end
        end

        def invalidate_hash_representation!
          @__hash_representation__ = nil
        end

        def create_setter(setter)
          define_singleton_method setter do |value|
            invalidate_hash_representation!
            instance_variable_set :"@#{setter_to_getter(setter)}", value
          end
        end
      end
    end
  end
end
