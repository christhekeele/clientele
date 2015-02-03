require 'clientele/request'
require 'clientele/response'
require 'clientele/utils'
require 'clientele/resource/pagination'

require 'active_support/core_ext/string/inflections'

module Clientele
  class Resource < SimpleDelegator
    include Clientele::Utils

    @subclasses = []

    class_attribute :client, instance_predicate: false
    self.client = nil

    class << self
      include Clientele::Utils

      attr_reader :subclasses

      Request::VERBS.each do |verb|
        define_method verb do |path_segment = '', opts = {}, &callback|
          path_segment, opts = opts[:path].to_s, path_segment.merge(opts) if path_segment.is_a? Hash
          Request.new(opts.merge(
            path: merge_paths(path, path_segment || opts[:path].to_s),
            resource: self,
            client: client.client
          ), &callback)
        end
      end

      def request(verb, path = '', opts = {}, &callback)
        send verb, path, opts, &callback
      end

      def to_request(opts={}, &callback)
        get opts, &callback
      end

      def default_path
        self.name.split('::').last.pluralize.underscore
      end

      def path
        @path || default_path
      end

      def method_name
        @method_name || path
      end

      def result_key
        @result_key || method_name.to_s.singularize
      end

      def result(data)
        data[result_key]
      end

      def results(data)
        result(data) if result(data) and result(data).kind_of?(Array)
      end

      def build(data, client: nil, response: nil)
        new(
          catch(:build) do
            if data.kind_of? Hash
              if many = results(data)
                build many, client: client#, response: response
              elsif one = result(data)
                throw :build, one
              else
                throw :build, data
              end
            elsif data.respond_to? :map
              data.map do |dataset|
                build dataset, client: client#, response: response
              end
            end
          end
        ).tap do |instance|
          instance.instance_variable_set :@client, client if client
          instance.instance_variable_set :@response, response if response
        end
      end

    private

      def inherited(base)
        @subclasses << base
      end

    end

    attr_accessor :response

  end
end
