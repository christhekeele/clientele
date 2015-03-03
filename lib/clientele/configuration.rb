require 'logger'

require 'faraday'
require 'faraday_middleware'

module Clientele
  class Configuration < BlockParty::Configuration

    attr_accessor :logger, :adapter, :headers, :hashify_content_type, :root_url, :follow_redirects, :redirect_limit, :ensure_trailing_slash, :faraday_configuration

    def initialize
      self.logger                = Logger.new($stdout)
      self.adapter               = Faraday.default_adapter
      self.headers               = {}
      self.hashify_content_type  = /\bjson$/
      self.follow_redirects      = true
      self.redirect_limit        = 5
      self.ensure_trailing_slash = true

      self.faraday_configuration = default_faraday_configuration
    end

    def default_faraday_configuration
      @default_faraday_configuration ||= Proc.new do |conn, options|

        conn.use FaradayMiddleware::FollowRedirects, limit: options[:redirect_limit] if options[:follow_redirects]

        conn.request  :url_encoded

        conn.response :rashify
        conn.response :logger, options[:logger], bodies: true
        conn.response :json, content_type: options[:hashify_content_type], preserve_raw: true

        conn.adapter options[:adapter] if options[:adapter]

        conn.options.params_encoder = options[:params_encoder] if options[:params_encoder]

      end
    end

  end
end
