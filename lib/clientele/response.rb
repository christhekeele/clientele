# require 'delegate'

module Clientele

  class Response# < SimpleDelegator

    class << self
      def build(response, client: nil, resource: nil)
        if resource
          resource.build response.body, response: response, client: client
        else
          new response.body
        end.tap do |instance|
          instance.instance_variable_set :@client,   client   if client
          instance.instance_variable_set :@response, response if response
        end
      end
    end

    def initialize(data)
      @data = data
    end

    attr_reader :data, :response, :client

  end
end
