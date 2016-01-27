require "forwardable"

require "clientele/client/configuration"
require "clientele/http/verbs"
require "clientele/request"

module Clientele
  class Client
    # Public: Client objects are the point of entry responsible for configuring
    # and issuing requests.

    extend Forwardable

    attr_accessor  :configuration
    def_delegators :configuration, :settings, :root, :connection
    def_delegators :configuration, :request_pipeline, :connection_pipeline, :response_pipeline

    def initialize(**options, &block)
      @configuration = Configuration.new.configure(options, &block)
    end

    def request(**options)
      Request.new(client: self, **options)
    end

    def configure(**options, &block)
      self.dup.tap do |client|
        client.configuration.configure(options, &block)
      end
    end

    Clientele::HTTP::Verb.methods.map(&:downcase).each do |verb|
      define_singleton_method verb do |root, **options|
        new(root: root).request(options.merge(verb: __method__)).call
      end
    end

    def call(request)
      request_pipeline.call(request) do |request|
        connection_pipeline.call(request) do |request|
          response_pipeline.call request.connection.call(request)
        end
      end
    end

  end
end
