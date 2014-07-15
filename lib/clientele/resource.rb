require 'clientele/request'
require 'clientele/utils'

require 'active_support/core_ext/string/inflections'

module Clientele
  class Resource
    include Clientele::Utils

    @subclasses = []

    class << self
      include Clientele::Utils
      attr_reader :subclasses
      attr_accessor :path

      def request(verb, path='', query: {}, body: {}, options: {}, &callback)
        Request.send(verb,
          path: merge_paths(@path || to_s, path),
          query: query,
          body: body,
          options: options,
          resource: self,
          &callback
        )
      end

      def to_request(options={}, &callback)
        request :get, options: options, callback: callback
      end

      def to_s
        self.name.split('::').last.pluralize.underscore
      end

    private

      def inherited(base)
        @subclasses << base
      end
    end

  end
end
