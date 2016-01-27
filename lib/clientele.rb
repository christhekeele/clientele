require "forwardable"
require "clientele/version"
require "clientele/client"
require "clientele/http/verbs"

module Clientele

  extend Forwardable
  extend SingleForwardable

module_function

  def client
    Client
  end

  def_instance_delegators :client, *Clientele::HTTP::Verb.methods.map(&:downcase)
  def_single_delegators   :client, *Clientele::HTTP::Verb.methods.map(&:downcase)

  class Error < StandardError; end

  class ClientError < Error
    attr_reader :response

    def initialize(ex, response = nil)
      @wrapped_exception = nil
      @response = response

      if ex.respond_to?(:backtrace)
        super(ex.message)
        @wrapped_exception = ex
      elsif ex.respond_to?(:status_code)
        super("the server responded with status #{ex.status_code}")
        @response = ex
      else
        super(ex.to_s)
      end
    end

    def backtrace
      if @wrapped_exception
        @wrapped_exception.backtrace
      else
        super
      end
    end

    def inspect
      %(#<#{self.class}: #{@wrapped_exception.class}>)
    end
  end

  class ConnectionFailed < ClientError;   end
  class ResourceNotFound < ClientError;   end
  class ParsingError     < ClientError;   end

  class Timeout < ClientError
    def initialize(ex = nil)
      super(ex || "timeout")
    end
  end

  class SSLError < ClientError
  end

end
