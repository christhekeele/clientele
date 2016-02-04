require 'clientele/pipeline/transforms'

module Clientele
  class Pipeline
    class Transforms
      class Before < self
        # Before forces yielding after transformation
        def apply(transform)
          Proc.new do |object, &block|
            block.call transform.call(object)
          end
        end
      end
    end
  end
end
