require 'clientele/request'
require 'clientele/utils'
require 'clientele/resource/pagination'

require 'active_support/core_ext/string/inflections'

module Clientele
  class Resource
    include Clientele::Utils

    @subclasses = []

    class << self
      include Clientele::Utils

      attr_reader :subclasses

      Request::VERBS.each do |verb|
        define_method verb do |path_segment = '', opts = {}, &callback|
          path_segment, opts = opts[:path].to_s, path_segment if path_segment.is_a? Hash
          Request.new(opts.merge(path: merge_paths(path, path_segment || opts[:path].to_s)), &callback)
        end
      end

      def request(verb, path = '', opts = {}, &callback)
        send verb, path, opts, &callback
      end

      def to_request(options={}, &callback)
        get options: options, &callback
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

    private

      def inherited(base)
        @subclasses << base
      end

    end

  end
end
