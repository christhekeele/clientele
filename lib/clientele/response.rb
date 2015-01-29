require 'delegate'

require 'faraday/response'

module Clientele
  class Response < Faraday::Response::Delegate = DelegateClass(Faraday::Response)

    attr_accessor :request, :resource
    def initialize(request, response)
      @request = request
      @resource = request.resource
      super response
    end

  end
end
