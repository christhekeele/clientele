require 'logger'

require "addressable"
require 'clientele/http/uri'

require 'clientele/configuration'
require 'clientele/adapter'
require 'clientele/pipeline'

module Clientele
  class Client
    class Configuration < Clientele::Configuration

      attr_accessor :logger
      attr_reader   :root, :timeout
      attr_writer   :pipeline

      def initialize
        @root       = nil
        @logger     = Logger.new($stdout)
        @timeout    = false
        @adapter    = Adapter.default
        @pipeline   = Adapter.for(@adapter)
        #
        self.pipeline do
          require 'clientele/transforms'
          before.transforms <<
            Transforms::Before::DefaultHeaders <<
            Transforms::Before::DefaultHeaders.inject('Fizz' => 'Buzz') <<
            Transforms::Before::EnsureTrailingSlash
          around Transforms::Around::FollowRedirects
        end

        attr_accessor :default_headers
        self.default_headers = {'Foo' => 'Bar'}

      end

      def root= uri
        @root = case uri
        when Addressable::URI
          uri
        else
          Addressable::URI.parse uri
        end
      end

      def timeout= value
        @timeout = if value
          Integer value
        else; value; end
      end

      def adapter= lookup
        Adapter.for(lookup)
      end

      def adapter &implementation
        if block_given?
          @adapter = implementation
        else
          @adapter
        end
      end

      def pipeline &implementation
        if block_given?
          @pipeline = Pipeline.new do |pipeline|
            pipeline.instance_eval &implementation
          end
        else
          @pipeline || @adapter
        end
      end

    end
  end
end
