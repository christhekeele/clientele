require 'singleton'

module Clientele
  class Adapter

    include Singleton

    class << self

      def for(lookup)
        if adapters.include? lookup
          lookup.instance
        elsif keys.map(&:to_sym).include? lookup.to_sym
          adapters.find do |adapter|
            adapter.key.to_sym == lookup.to_sym
          end.instance
        elsif lookup.respond_to? :to_proc
          lookup.to_proc
        elsif lookup.response_to? :call
          lookup
        else
          raise "Adapter `#{lookup}` not found"
        end
      end

      def keys
        adapters.map(&:key)
      end

      def key
        self.name.split('::').last.gsub(/(.)([A-Z])/,'\1_\2').downcase.to_sym
      end

      def default
        :net_http
      end

    private

      def adapters
        Adapters.constants.map do |name|
          Adapters.const_get name
        end.select do |constant|
          constant.class != Module
        end
      end

    end

  end
end

require 'clientele/adapters/net_http'
