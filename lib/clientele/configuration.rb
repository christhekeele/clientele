require 'logger'

require 'faraday'

module Clientele
  class Configuration < BlockParty::Configuration

    attr_accessor :logger, :adapter, :headers, :resources, :root_url

    def initialize
      self.logger   =  Logger.new($stdout)
      self.adapter  =  Faraday.default_adapter
      self.headers  =  {}
      self.resources = []
    end

  end
end
