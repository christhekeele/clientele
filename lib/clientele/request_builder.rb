require 'clientele/api'
require 'clientele/utils'

module Clientele
  class RequestBuilder
    include Clientele::Utils
    include Enumerable
    attr_accessor :stack, :client

    def initialize(*request_components, client: API.client)
      @stack = request_components.flatten
      @client = client
    end

    def call
      build.call
    end

  protected

    def build
      stack.map(&:to_request).inject(:+).to_request(client: client)
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
      if chain.respond_to? method_name, :public
        chain_method method_name, *args, &block
      elsif client.has_resource? method_name
        chain_resource method_name
      elsif should_paginate? method_name
        chain.send :each, build, &block
      else; super; end
    end

    def respond_to_missing?(method_name, include_private=false)
      chain.respond_to? method_name, :public \
        or client.has_resource? method_name \
        or should_paginate? method_name \
        or super
    end

    def chain
      stack.last
    end

    def chain_method(method_name, *args, &block)
      stack << stack.pop.send(method_name, *args, &block) and self
    end

    def chain_resource(resource_name)
      stack << client.resources[resource_name.to_s] and self
    end

    def should_paginate?(method_name)
      chain.instance_variable_get :@paginateable \
        and enumberable_methods.include? method_name
    end

    def enumberable_methods
      Enumerable.instance_methods - Module.instance_methods << :each
    end

  end
end
