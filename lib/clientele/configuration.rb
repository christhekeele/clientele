require 'logger'

require 'faraday'

module Clientele
  class Configuration < BlockParty::Configuration

    attr_accessor :logger, :adapter, :headers, :hashify_content_type, :root_url, :follow_redirects, :redirect_limit

    def initialize
      self.logger                =  Logger.new($stdout)
      self.adapter               =  Faraday.default_adapter
      self.headers               =  {}
      self.hashify_content_type  = /\bjson$/
      self.follow_redirects      = true
      self.redirect_limit        = 5
      self.ensure_trailing_slash = true
    end

  end
end
