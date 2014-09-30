require 'json'

require 'faraday'
require 'faraday_middleware'
require 'rash'

require 'clientele/utils'

module Clientele
  class Request < Struct.new(:verb, :path, :query, :body, :headers, :options, :callback, :resource)
    include Clientele::Utils

    VERBS = %i[get post put patch delete]
    VERBS.each do |verb|
      define_singleton_method verb do |opts={}, &callback|
        new opts.merge(verb: __method__, callback: callback)
      end
    end

    def initialize(props={})
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
      callback ? callback.call(response) : response
    end
    alias_method :~, :call

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
      )
    end

  private

    def response
      faraday_client.send(verb, ensure_trailing_slash(path)) do |request|
        request.headers = options.fetch(:headers, {}).merge(headers)
        request.params  = deep_camelize_keys(query)
        request.body    = JSON.dump(deep_camelize_keys(body))
      end
    end

    def faraday_client
      Faraday.new(options[:root_url]) do |conn|
        conn.response :rashify
        conn.response :json, content_type: options[:hashify_content_type], preserve_raw: true
        conn.adapter options[:adapter]
      end
    end

    class << self
      def defaults
        {
          verb:     :get,
          path:     nil,
          query:    {},
          body:     {},
          headers:  {},
          options:  {},
          callback: nil,
          resource: nil,
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
