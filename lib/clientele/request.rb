require 'json'

require 'faraday'
require 'faraday_middleware'
require 'rash'

require 'clientele/utils'
require 'clientele/response'

module Clientele
  class Request < Struct.new(*%i[
      verb
      path
      query
      body
      headers
      options
      callback
      resource
      client
    ])

    include Clientele::Utils

    VERBS = Faraday::Connection::METHODS

    VERBS.each do |verb|
      define_singleton_method verb do |path = '', opts = {}, &callback|
        new(
          opts.tap do |opts|
            opts.merge!(verb: __method__)
#           opts.merge!(path: path) unless opts[:path]
#           opts.merge!(callback: callback) if callback
          end
        )
      end
    end

    def initialize(props = {})
      apply self.class.defaults
      apply props
    end

    def async?
      !!callback
    end

    def url
      ensure_trailing_slash merge_paths options[:root_url], path
    end

    def to_request(options={})
      tap do |request|
        request.options.deep_merge! options
      end
    end

    def call
      options.deep_merge! client.configuration.to_hash if client
      callback ? callback.call(result) : result
    end

    def + other
      self.class.new(
        verb:     other.verb || verb,
        path:     merge_paths(path, other.path),
        query:    query.merge(other.query),
        body:     body.merge(other.body),
        headers:  headers.merge(other.headers),
        options:  options.merge(other.options),
        callback: other.callback || callback,
        resource: other.resource || resource,
        client:   client || other.client,
      )
    end

  private

    def result
      Response.build(response, resource, client)
    end

    def response
      request_path = options[:ensure_trailing_slash] ? ensure_trailing_slash(path) : path
      @response ||= faraday_client.send(verb, request_path) do |request|
        request.headers = options.fetch(:headers, {}).merge(headers)
        request.params  = deep_camelize_keys(query)
        request.body    = JSON.dump(deep_camelize_keys(body))
      end
    end

    def faraday_client
      Faraday.new(options[:root_url]) do |connection|
        if options[:connection]
          options[:connection].call connection, options
        end
      end
    end

    class << self
      def defaults
        {
          verb:     :get,
          path:     '',
          query:    {},
          body:     {},
          headers:  {},
          options:  {},
          callback: nil,
          resource: nil,
          client:   nil,
        }
      end
    end

    def apply(hash={})
      hash.each do |key, value|
        self.send :"#{key}=", value
      end
    end

  end
end
