require "forwardable"

require 'clientele/http/request'

require "clientele/client"
require "clientele/utils"

module Clientele
  class Request < HTTP::Request

    extend Forwardable
    include Utils::DeepCopy
    include Utils::DeepFreeze

    attr_reader    :client
    def_delegators :client, :config

    def initialize(client: nil, **options)
      @client = if client.kind_of? Hash
        Client.new client
      else
        client
      end
      verb = options.delete(:verb) || :get
      headers = options.delete(:headers) || {}
      body = options.delete(:body)
      path = Array(options.delete(:path)).flatten.map(&:to_s).join('/')
      uri = config.root.merge(options.merge(path: path))
      super verb, uri, headers, body
      # yield response if block_given?
    end

    def call
      client.call(self)
    end
    
    def call!
      client.call!(self)
    end

  # IMPL

    def body_receiver
      @body_receiver ||= [nil, BodyReceiver.new]
    end

    class BodyReceiver
      def initialize
        @chunks = []
      end

      def call(res, chunk)
        @chunks << chunk
      end

      def join
        @chunks.join
      end
    end

  end
end
