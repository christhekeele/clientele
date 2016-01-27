require "forwardable"

require "clientele/client"
require 'clientele/http/request'

module Clientele
  class Request < HTTP::Request

    extend Forwardable

    attr_reader    :client
    def_delegators :client, :configuration, :root

    def initialize(client: nil, **options)
      @client = if client.kind_of? Hash
        Client.new client
      else
        client
      end
      uri = root + '/' + options[:path].to_s
      super options[:verb] || :get, uri, options[:headers] || {}, options[:body]
      # yield response if block_given?
    end

    def call
      client.call(self)
    end
    alias_method :response, :call

    def io
      return unless body

      if body.respond_to?(:read)
        body
      elsif body
        StringIO.new(body)
      end
    end

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
