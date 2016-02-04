module Clientele
  class Pipeline
    class Transforms

      attr_accessor :transforms
      def initialize(*transforms)
        @transforms = transforms
      end

      def call(object, &block)
        block = default_block unless block_given?
        if @transforms and not @transforms.empty?
          composed_transforms.call object
        else
          block.call object
        end
      end

      def to_proc
        Proc.new do |object, &block|
          call object, &block
        end
      end

    private

      def default_block
        Proc.new do |object|
          object
        end
      end

      def composed_transforms
        @transforms.reverse.map do |transform|
          apply transform
        end.reduce(block) do |composition, transform|
          compose_transform(composition, transform)
        end
      end

      def compose_transform(composition, transform)
        abortable_transform do
          transform.call(object, &composition)
        end
      end

      def abortable_transform
        Proc.new do |object|
          if not object.nil?
            yield
          else
            nil
          end
        end
      end

    end
  end
end

require 'clientele/pipeline/transforms/before'
require 'clientele/pipeline/transforms/around'
require 'clientele/pipeline/transforms/after'
