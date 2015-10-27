require 'forwardable'

require 'active_support/core_ext/class/attribute'
require 'block_party'
require 'rash'

require 'clientele/configuration'
require 'clientele/request_builder'
require 'clientele/request'
require 'clientele/resource'
require 'clientele/response'

module Clientele
  class API

    extend BlockParty::Configurable
    configure_with Configuration

    extend SingleForwardable
    extend Forwardable
    def_single_delegator :configuration, :logger
    # def_instance_delegator self, :has_resource?

    class_attribute :resources, instance_predicate: false
    self.resources = Hashie::Rash.new

    class << self

      def client(opts={})
        autoconfigure!
        if @client
          @client.tap do |client|
            client.configuration.load_hash(opts)
          end
        else
          @client = new(opts)
        end
      end

      def logger
        autoconfigure!
        configuration.logger
      end

      def resource(klass)
        klass.client = self
        self.resources = resources.merge(klass.method_name.to_sym => klass)
      end

      def has_resource?(resource)
        resources.keys.include? resource.to_s
      end

      def reset_global_client!
        @client = nil
      end

      def reconfigure_global_client!(opts={})
        reset_global_client!
        client(opts)
      end

    private

      def autoconfigure!
        self.configure unless configuration
      end

      def respond_to_missing?(method_name, include_private=false)
        client.respond_to? method_name, include_private
      end

      def method_missing(method_name, *args, &block)
        autoconfigure!
        if respond_to_missing?(method_name.to_s, false)
          client.send method_name, *args, &block
        else; super; end
      end

    end

    def initialize(opts={})
      self.extend BlockParty::Configurable
      self.configure_with self.class.configuration.class
      self.configuration = self.class.configuration.clone
      self.configuration.load_hash opts
    end

    def client; self; end

  private

    def respond_to_missing?(method_name, include_private=false)
      resources.keys.include?(method_name.to_s) or Request::VERBS.include?(method_name) or super
    end

    def method_missing(method_name, *args, &block)
      if resources.keys.include? method_name.to_s
        RequestBuilder.new(resources[method_name.to_s], client: self)
      elsif Request::VERBS.include? method_name.to_s
        RequestBuilder.new(Request.send(method_name.to_s, *args), client: self)
      else; super; end
    end

  end
end
