require 'clientele/pipeline/transforms'
require 'clientele/utils'

module Clientele
  class Pipeline

    include Utils::DeepCopy
    include Utils::DeepFreeze

    def initialize(&implementation)
      @before = Transforms::Before.new
      @around = Transforms::Around.new
      @after  = Transforms::After.new
      instance_eval &implementation if block_given?
    end

    def before(*transforms, &block)
      if not transforms.empty?
        @before.transforms += transforms
      elsif block_given?
        @before.transforms << block
      else
        @before
      end
    end

    def around(*transforms, &block)
      if not transforms.empty?
        @around.transforms += transforms
      elsif block_given?
        @around.transforms << block
      else
        @around
      end
    end

    def after(*transforms, &block)
      if not transforms.empty?
        @after.transforms += transforms
      elsif block_given?
        @after.transforms << block
      else
        @after
      end
    end

    def call(object)
      @before.call object do |object|
        result = @around.call object do |object|
          block_given? ? yield(object) : object
        end
        @after.call result
      end
    end

    def to_proc
      Proc.new do |object, &block|
        call object, &block
      end
    end

  end
end
