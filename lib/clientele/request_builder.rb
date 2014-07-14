require 'clientele/api'
require 'clientele/utils'

module Clientele
  class RequestBuilder
    include Clientele::Utils

    def initialize(*resources, client: API.client)
      @stack = Array(resources)
      @client = client
    end

    def call
      build.call
    end
    alias_method :~, :call

  protected

    def build
      @stack.map(&:to_request).inject(:+).to_request(@client.configuration.to_hash)
    end

    def to_a
      @stack
    end

    # Compare values only, class doesn't matter
    def == other
      to_a.zip(other.to_a).all? do |mine, theirs|
        mine == theirs
      end
    end

    # Compare values only, class matters
    def eql?(other)
      if other.is_a?(RequestBuilder)
        to_a.zip(other.to_a).all? do |mine, theirs|
          mine.eql? theirs
        end
      end
    end

    # Compare classes or instances for case statements
    def === other
      unless other.is_a? Class
        to_a == other.to_a if other.respond_to? :to_a
      else
        super
      end
    end

    def to_s
      merge_paths(@stack.map(&:to_s))
    end

  private

    def method_missing(method_name, *args, &block)
      if API::resources.keys.include? method_name
        @stack << API::resources[method_name]
        self
      elsif @stack.last.respond_to? method_name, false
        @stack = @stack[0..-2] << @stack.last.send(method_name, *args, &block)
        self
      else; super; end
    end
    def respond_to_missing?(method_name, include_private=false)
      API::resources.keys.include?(method_name) \
      or @stack.last.respond_to?(method_name, include_private) \
      or super
    end

  end
end
