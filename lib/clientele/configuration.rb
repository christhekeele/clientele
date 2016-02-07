require 'clientele/utils'

module Clientele
  class Configuration

    include Utils::DeepCopy
    include Utils::DeepFreeze

    def configure(options = {})
      self.load_hash(options).tap do |config|
        yield(config) if block_given?
      end
    end

    def method_missing(setting, *args, &block)
      setter, getter = derive_setting_names(setting)
      create_accessors setter, getter
      if setter? setting
        set setter, *args, &block
      else
        set_nested_configuration setter, *args, &block
      end
    end

    def instance_variables
      super.reject do |var|
        [:"@__hash_representation__", :"@__hash_representation__="].include? var
      end
    end

    def settings
      instance_variables.map do |var|
        var.to_s.gsub('@', '').to_sym
      end
    end

    def unset(setting)
      setting = setting.to_sym
      setting = :"@#{setting}" unless setting.to_s =~ /^@/
      remove_instance_variable setting
    end

  protected

    def derive_setting_names(setting_name)
      if setter? setting_name
        [ setting_name, setter_to_getter(setting_name) ]
      else
        [ getter_to_setter(setting_name), setting_name ]
      end
    end

    def setter?(setting)
      setting =~ /=$/
    end

    def create_accessors(setter, getter)
      create_setter(setter)
      create_getter(getter)
    end

    def create_setter(setter)
      define_singleton_method setter do |value|
        instance_variable_set :"@#{setter_to_getter(setter)}", value
      end
    end

    def create_getter(getter)
      define_singleton_method getter do
        instance_variable_get :"@#{getter}"
      end
    end

    def setter_to_getter(setter)
      :"#{setter.to_s.gsub('=','')}"
    end

    def getter_to_setter(getter)
      :"#{getter}="
    end

    def set(setter, *args, &block)
      if block_given?
        send setter, *args, &block
      else
        send setter, *args
      end
    end

    def set_nested_configuration(setter, *args, &block)
      configuration = send setter, Configuration.new
      yield(configuration) if block_given?
      configuration
    end

  public

  ####
  # CONVERSION
  ##

    class << self

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

  ####
  # COMPARISON
  ##

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

  ####
  # IDENTITY
  ##

    def hash
      as_hash.hash
    end

    def empty?
      instance_variables.empty?
    end

  ####
  # ENUMERATION
  ##

    include Enumerable
    def each(*args, &block)
      to_hash.each(*args, &block)
    end

  end
end
