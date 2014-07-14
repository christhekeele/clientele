require 'logger'

require 'faraday'

module Clientele
  class Configuration < BlockParty::Configuration

    attr_accessor :logger, :adapter, :headers, :root_url

    def initialize
      self.logger   =  Logger.new($stdout)
      self.adapter  =  Faraday.default_adapter
      self.headers  =  {}
    end

  end
end
