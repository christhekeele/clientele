require 'clientele/utils'

module Clientele
  class Pipeline
    class Transforms

      include Utils::DeepCopy
      include Utils::DeepFreeze

      attr_accessor :transforms
      def initialize(*transforms)
        @transforms = transforms
      end

      def call(object, &block)
        block = default_block unless block_given?
        if @transforms and not @transforms.empty?
          @transforms.reverse.map do |transform|
            apply transform
          end.reduce(block) do |composition, transform|
            Proc.new do |object|
              if not object.nil?
                transform.call(object, &composition)
              else
                nil
              end
            end
          end.call object
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

    end
  end
end

require 'clientele/pipeline/transforms/before'
require 'clientele/pipeline/transforms/around'
require 'clientele/pipeline/transforms/after'
