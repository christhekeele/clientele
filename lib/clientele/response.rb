require "forwardable"

require 'clientele/request'
require 'clientele/http/response'

module Clientele
  class Response < HTTP::Response

    extend Forwardable

    attr_reader    :request
    def_delegators :request, :configuration, :connection, :root

    def initialize(request: nil, **options)
      @request = if request.kind_of? Hash
        Request.new request
      else
        request
      end
      status = Clientele::HTTP::Status.for options[:status]
      super status, options[:headers] || {}, options[:body]
    end


    def call

    end

    def receive_body(chunk)
      return if chunk.nil?

      if @receiver.nil?
        statuses, receiver = request.send(:body_receiver)
        @receiver = if statuses && !statuses.include?(@status_code)
          BodyReceiver.new
        else
          receiver
        end
      end

      @receiver.call(self, chunk)
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
