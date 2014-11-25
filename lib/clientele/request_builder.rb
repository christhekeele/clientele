require 'clientele/api'
require 'clientele/utils'

module Clientele
  class RequestBuilder
    include Clientele::Utils
    include Enumerable
    attr_accessor :stack, :client
    alias_method :to_a, :stack

    def initialize(*request_components, client: API.client)
      @stack = request_components.flatten
      @client = client
    end

    def call
      build.call
    end

  protected

    def build
      stack.map(&:to_request).inject(:+).to_request(client.configuration.to_hash)
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

    def path
      merge_paths(stack.map(&:path))
    end

  private

    def method_missing(method_name, *args, &block)
      if client.resources.keys.include? method_name
        tap { |builder| builder.stack << client.resources[method_name] }
      elsif stack.last.respond_to? :each_with_builder and method_name == :each
        stack.last.each_with_builder(self, &block)
      elsif stack.last.respond_to? method_name, false
        tap { |builder| builder.stack = builder.stack[0..-2] << builder.stack.last.send(method_name, *args, &block) }
      else; super; end
    end

    def respond_to_missing?(method_name, include_private=false)
      API::resources.keys.include?(method_name) \
        or stack.last.respond_to?(method_name, include_private) \
        or super
    end

  end
end
