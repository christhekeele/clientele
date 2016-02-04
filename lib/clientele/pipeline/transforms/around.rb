require 'clientele/pipeline/transforms'

module Clientele
  class Pipeline
    class Transforms
      class Around < self
        # Around expects the transformation itself to yield
        def apply(transform)
          transform
        end
      end
    end
  end
end
