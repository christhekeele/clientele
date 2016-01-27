require 'logger'
require 'uri'

require 'clientele/utils/configuration'
require 'clientele/http/headers'
require 'clientele/connection'
require 'clientele/pipeline'

module Clientele
  class Client
    class Configuration < Clientele::Utils::Configuration

      attr_accessor :logger, :headers, :follow_redirects, :redirect_limit, :connection
      attr_reader   :root, :headers, :request_pipeline, :response_pipeline, :connection_pipeline

      def initialize
        self.logger            = Logger.new($stdout)
        self.headers           = {}
        self.follow_redirects  = true
        self.redirect_limit    = 5
        self.connection        = Clientele::Connection
        self.timeout           = false
        @request_pipeline      = Pipeline.before(:status) do
          def status(request)
            request.tap do
              puts "before: #{request}"
            end
          end
        end
        @response_pipeline     = Pipeline.after(:status) do
          def status(response)
            response.tap do
              puts "after: #{response}"
            end
          end
        end
        @connection_pipeline   = Pipeline.around(:status) do
          def status(request)
            puts "preyield: #{request}"
            response = yield request
            puts "postyield #{response}"
          end
        end
      end

      def root= uri
        case uri
        when URI
          @root = uri
        else
          @root = URI.parse uri
        end
      end

      def headers= hash
        HTTP::Headers.new(hash, type: :request)
      end

      def request_pipeline= *args, &block
        Pipeline.before *args, &block
      end
      def response_pipeline= *args, &block
        Pipeline.after *args, &block
      end
      def connection_pipeline= *args, &block
        if block_given?
          Pipeline.around *args, &block
        else
          Pipeline.before *args
        end
      end

    end
  end
end
