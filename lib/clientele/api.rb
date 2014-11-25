require 'forwardable'

require 'block_party'
require 'active_support/core_ext/class/attribute'

require 'clientele/configuration'
require 'clientele/request_builder'
require 'clientele/request'
require 'clientele/resource'

module Clientele
  class API

    extend BlockParty::Configurable
    configure_with Configuration

    extend SingleForwardable
    def_delegator :configuration, :logger

    class_attribute :resources, instance_predicate: false
    self.resources = {}

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
        self.resources = resources.merge(klass.method_name.to_sym => klass)
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
        if respond_to_missing?(method_name, false)
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

  private

    def respond_to_missing?(method_name, include_private=false)
      resources.keys.include?(method_name) or Request::VERBS.include?(method_name) or super
    end

    def method_missing(method_name, *args, &block)
      if resources.keys.include? method_name
        RequestBuilder.new(resources[method_name], client: self)
      elsif Request::VERBS.include? method_name
        RequestBuilder.new(Request.send(method_name, *args), client: self)
      else; super; end
    end

  end
end
