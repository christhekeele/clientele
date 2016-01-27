module Clientele
  class Pipeline < Module

    attr_accessor :transforms
    def initialize(*transforms, &implementation)
      @transforms = transforms
      instance_eval &implementation if block_given?
    end

    def call(*args, &block)
      transformers.reduce(block || default_block) do |pipeline, transformer|
        -> *args { transformer.call(*args, &pipeline) }
      end.call *args
    end

    class Before < self
      # Use default behavior
    end

    class After < self
      def apply(transformer)
        -> *args, &block {
          transformer.call *block.call(*args)
        }
      end
    end

    class Around < self
      # Rely on implementation to yield
      def apply(transformer)
        transformer
      end
    end

    class << self

      def before(*args, &block)
        Before.new(*args, &block)
      end

      def after(*args, &block)
        After.new(*args, &block)
      end

      def around(*args, &block)
        Around.new(*args, &block)
      end

    end

  private

    def transformers
      transforms.reverse.map do |transform|
        transformer_for transform
      end.compact.map do |transformer|
        apply transformer
      end
    end

    def apply(transformer)
      -> *args, &block {
        block.call *transformer.call(*args)
      }
    end

    def transformer_for(transform)
      if transform.respond_to? :call
        transform
      elsif transform.respond_to? :to_sym
        method transform.to_sym
      end
    end

    def default_block
      -> *args {
        case args.length
        when 0; nil
        when 1; args.first;
        else args; end
      }
    end

  end
end
