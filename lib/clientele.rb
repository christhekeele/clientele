require "forwardable"

require "clientele/http"

require "clientele/version"
require "clientele/client"

module Clientele

  extend Forwardable
  extend SingleForwardable

  class Exception < StandardError; end

  class ConnectionFailed < Exception;   end
  class ResourceNotFound < Exception;   end
  class ParsingError     < Exception;   end

  class Timeout < Exception
    def initialize(ex = nil)
      super(ex || "timeout")
    end
  end

  class SSLError < Exception
  end

module_function

  def client(*args, **options, &block)
    Client.new *args, **options, &block
  end

  def_instance_delegators Client, *Clientele::Client::PROXY_METHODS
  def_single_delegators   Client, *Clientele::Client::PROXY_METHODS
  def_instance_delegators Client, *Clientele::Client::BANG_PROXY_METHODS
  def_single_delegators   Client, *Clientele::Client::BANG_PROXY_METHODS

end
