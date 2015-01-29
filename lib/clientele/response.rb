require 'delegate'

require 'faraday/response'

module Clientele

  class Response < SimpleDelegator

    attr_reader :response
    def initialize(response, client: nil, resource: nil)
      @response = response
      super(
        if resource
          resource.build response.body, client: client, klass: response.body.class
        else
          response.body
        end
      )
    end

    def respond_to_missing?(method_name, include_private=false)
      @response.respond_to?(method_name, include_private) or super
    end

    def method_missing(method_name, *args, &block)
      begin
        super
      rescue NoMethodError
        @response.send method_name, *args, &block
      end
    end

  end
end
