require "clientele/http/verbs"

require 'clientele/utils'

require "clientele/client/configuration"
require "clientele/request"
require "clientele/adapter"

module Clientele
  class Client

    include Utils::DeepCopy
    include Utils::DeepFreeze

    attr_accessor :configuration
    alias_method  :config, :configuration

    def initialize(configuration = config_class, **options, &block)
      @configuration = configuration.new.configure(**options, &block)
    end
    
    def config_class
      self.class.config_class
    end

    def request(**options)
      Request.new(client: self, **options)
    end

    def configure(**options, &block)
      self.dup.tap do |client|
        client.config.configure(options, &block)
      end
    end

    def call(request)
      config.pipeline.call(request) do |request|
        request.config.adapter.call request
      end
    end

    def call!(request)
      call(request).tap do |response|
        raise response.status.error if response.status.error?
      end
    end

    class << self
    
      def config_class
        Configuration
      end

      def request(verb, root, **options)
        new(root: root).request(options.merge(verb: verb))
      end

      def call(verb, root, **options)
        request(verb, root, **options).call
      end

      def call!(verb, root, **options)
        request(verb, root, **options).call!
      end

    end

    PROXY_METHODS = Clientele::HTTP::Verb.methods + Clientele::HTTP::Verb.methods.map(&:downcase)

    PROXY_METHODS.each do |verb|

      define_singleton_method verb do |root, **options|
        call(verb, root, **options)
      end

      define_method verb do |**options|
        request(options.merge(verb: verb)).call
      end

    end

    BANG_PROXY_METHODS = PROXY_METHODS.map{ |method| :"#{method}!" }

    BANG_PROXY_METHODS.each do |bang|

      define_singleton_method bang do |root, **options|
        call!(bang[0..-2], root, **options)
      end

      define_method bang do |**options|
        request(options.merge(verb: bang[0..-2])).call!
      end

    end

  end
end
