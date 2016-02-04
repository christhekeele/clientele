require "net/http"

require "clientele/adapter"
require "clientele/response"

module Clientele
  module Adapters

    class NetHTTP < Clientele::Adapter

      class << self
        def key
          :net_http
        end
      end

      def call(request)
        conn = connection_from request
        net_http_request = request_from request
        net_http_response = conn.request net_http_request
        response_from request, net_http_response
      end

    private

      def connection_from(request)
        Net::HTTP.new(request.uri.host, request.uri.port).tap do |http|
          if t = request.config.timeout
            http.read_timeout = http.open_timeout = t
          end
        end
      end

      def request_from(request)
        Net::HTTPGenericRequest.new(
          request.verb,
          request.has_body?,
          request.expects_response_body?,
          request.uri.request_uri,
          request.headers.to_h,
        ).tap do |net_http|
          if request.has_body?
            net_http.body_stream = request.body.stream
          end
        end
      end

      def response_from(request, net_http_response)
        Response.new(
          request: request,
          status: net_http_response.code,
          headers: net_http_response.enum_for(:each_capitalized).reduce({}) do |headers, (key, value)|
            headers.tap do |headers|
              headers[key] = value
            end
          end,
          body: net_http_response.body
        )

        # if :get == request.verb
        #   request.read_body { |chunk| response.receive_body(chunk) }
        # else
        #   response.receive_body(request.body)
        # end
      end

    end
  end
end
