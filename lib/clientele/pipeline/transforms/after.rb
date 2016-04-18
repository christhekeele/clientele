require 'clientele/pipeline/transforms'

module Clientele
  class Pipeline
    class Transforms
      class After < self
        
        def ordered_transforms
          super.reverse
        end
        
        # After forces yielding before transformation
        def apply(transform)
          Proc.new do |object, &block|
            transform.call block.call(object)
          end
        end
      end
    end
  end
end
