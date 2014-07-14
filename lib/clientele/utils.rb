require 'active_support/core_ext/hash'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/string/inflections'

module Clientele
  module Utils

  module_function

    def merge_paths(*urls)
      ensure_trailing_slash urls.reject(&:blank?).join('/').sub(/(?<!:)\/+/, '/')
    end

    def ensure_trailing_slash(url)
      url.end_with?('/') ? url : url + '/'
    end

    def deep_camelize_keys(hash)
      hash.deep_transform_keys do |key|
        key.to_s.camelize(:lower)
      end
    end

  end
end
