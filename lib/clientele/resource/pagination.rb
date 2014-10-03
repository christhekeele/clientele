module Clientele
  class Resource
    module Pagination

      def paginate(method_name, &implementation)
        mixin = Module.new do
           define_method method_name do |*args, &block|
            super(*args, &block).tap do |request|
              request.extend(Iterator)
              request.class_eval(&default_implementation)
              request.class_eval(&implementation) if implementation
            end
          end
        end
        const_set :"#{method_name.to_s.capitalize}Pagination", mixin
        singleton_class.prepend mixin
      end

    private

      def default_implementation
        Proc.new do

          def next_page(request)
            request.query[:page] += 1
          end

          def total(response)
            response.headers.fetch('x-total-count', Float::INFINITY)
          end

          def pages(response)
            response.body.values.first
          end

        end
      end

      module Iterator

        def each_with_builder(builder)
          return enum_for(:each_with_builder) unless block_given?

          counter = 0
          current_response = builder.call

          until counter == total(current_response) do
            if pages(current_response).empty?
              current_response = builder.tap do |builder|
                next_page(builder.stack.last)
              end.call
            else
              counter +=1
              yield pages(current_response).shift
            end
          end

        end

      end

    end
  end
end
