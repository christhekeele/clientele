require "net/http"

require "clientele/response"

module Clientele
  module Connection

  module_function

    def call(request)
      net_http_connection(request) do |http|
        begin
          # Response.new(request: request).tap do |response|
          response = perform_request(http, request)
          # binding.pry

            # net/http only raises exception on 407 with ssl...?
            if response.status == 407
              raise ConnectionFailed, %(407 "Proxy Authentication Required")
            else
              response
            end
          # end
        rescue *NET_HTTP_EXCEPTIONS => err
          if defined?(OpenSSL) && OpenSSL::SSL::SSLError === err
            raise SSLError, err
          else
            raise ConnectionFailed, err
          end
        end
      end

    rescue ::Timeout::Error => err
      raise Timeout, err
    end

    def net_http_connection(request)
      # http = if proxy = request.options.proxy
      #   Net::HTTP::Proxy(proxy.host, proxy.port, proxy.user, proxy.password)
      # else
      #   Net::HTTP
      # end.new(request.url.host, request.url.port)
      http = Net::HTTP.new(request.root.host, request.root.port)

      # configure_ssl(http, request) if request.url.scheme == Hurley::HTTPS

      if t = request.configuration.timeout
        http.read_timeout = http.open_timeout = t
      end

      # if t = request.options.open_timeout
      #   http.open_timeout = t
      # end

      yield http
    end

    def net_http_request(request)
      http_req = Net::HTTPGenericRequest.new(
        request.verb.to_s.upcase, # request method
        !!request.body,           # is there a request body
        :head != request.verb,    # is there a response body
        request.root.request_uri,  # request uri path
        request.headers.to_h,           # request headers
      )

      if body = request.io
        http_req.body_stream = body
      end

      http_req
rescue => e
  binding.pry
    end

    def perform_request(http, request)
      http_res = http.request(net_http_request(request))# do |http_res|
        status = http_res.code.to_i

        http_res.each_header do |key, value|
          # response.headers[key] = value
        end

        # if :get == request.verb
        #   http_res.read_body { |chunk| response.receive_body(chunk) }
        # else
        #   response.receive_body(http_res.body)
        # end
        body = http_res.body
        Response.new(request: request, status: status, body: body)
      # end
rescue => e
  binding.pry
    end

    def configure_ssl(http, request)
      ssl = request.ssl_options
      http.use_ssl = true
      http.verify_mode = ssl.openssl_verify_mode
      http.cert_store = ssl.openssl_cert_store

      http.cert = ssl.openssl_client_cert if ssl.openssl_client_cert
      http.key = ssl.openssl_client_key if ssl.openssl_client_key
      http.ca_file = ssl.ca_file if ssl.ca_file
      http.ca_path = ssl.ca_path if ssl.ca_path
      http.verify_depth = ssl.verify_depth if ssl.verify_depth
      http.ssl_version = ssl.version if ssl.version
rescue => e
  binding.pry
    end

    NET_HTTP_EXCEPTIONS = [
      EOFError,
      Errno::ECONNABORTED,
      Errno::ECONNREFUSED,
      Errno::ECONNRESET,
      Errno::EHOSTUNREACH,
      Errno::EINVAL,
      Errno::ENETUNREACH,
      Net::HTTPBadResponse,
      Net::HTTPHeaderSyntaxError,
      Net::ProtocolError,
      SocketError,
      Zlib::GzipFile::Error,
    ]

    NET_HTTP_EXCEPTIONS << OpenSSL::SSL::SSLError if defined?(OpenSSL)
    NET_HTTP_EXCEPTIONS << Net::OpenTimeout if defined?(Net::OpenTimeout)

  end
end
