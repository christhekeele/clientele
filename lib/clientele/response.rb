require 'delegate'

require 'faraday/response'

module Clientele

  class Response < SimpleDelegator

    class << self
      def build(response, resource, client)
        if resource
          resource.build(response.body, response: response, client: client)
        else
          new response
        end
      end
    end

    attr_reader :response
    def initialize(response)
      super @response = response
    end

  end
end
