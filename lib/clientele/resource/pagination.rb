module Clientele
  class Resource# < SimpleDelegator
    module Pagination

      def paginate(method_name, &implementation)
        mixin = Module.new do
           define_method method_name do |*args, &block|
            super(*args, &block).tap do |request|
              request.extend(Enumerable) unless request.kind_of? Enumerable
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
            request.query[:page] ||= 1
            request.query[:page]  += 1
          end

          def total(result)
            Integer(result.response.headers['x-total-count']) or Float::INFINITY
          end

          def pages(result)
            result
          end

        end
      end

      module Iterator

        @paginateable = true

        def each(request = self.to_request)
          return enum_for(:each, request) unless block_given?

          counter = 0
          current_response = request.call

          until counter == total(current_response) do
            if pages(current_response).empty?
              current_response = request.tap do |request|
                next_page(request)
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
