require 'clientele/pipeline/transforms'

module Clientele
  class Pipeline

    def initialize(&implementation)
      @before = Transforms::Before.new
      @around = Transforms::Around.new
      @after  = Transforms::After.new
      instance_eval &implementation if block_given?
    end

    def before(*transforms)
      if not transforms.empty?
        @before = Transforms::Before.new *transforms
      else
        @before
      end
    end

    def around(*transforms)
      if not transforms.empty?
        @around = Transforms::Around.new *transforms
      else
        @around
      end
    end
    
    def after(*transforms)
      if not transforms.empty?
        @after  = Transforms::After.new *transforms
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
