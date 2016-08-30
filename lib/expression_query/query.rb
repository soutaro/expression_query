module ExpressionQuery
  module Query
    module Expr
      class Base; end

      class Call < Base
        attr_reader :receiver
        attr_reader :name
        attr_reader :args
        attr_reader :with_block

        def initialize(receiver:, name:, args:, with_block: nil)
          @receiver = receiver
          @name = name
          @args = args
          @with_block = with_block
        end
      end

      class Star < Base
      end

      class Underscore < Base
      end

      class Question < Base
      end

      class Literal < Base
        attr_reader :type

        def initialize(type:)
          @type = type
        end
      end

      class Value < Base
        attr_reader :value

        def initialize(value:)
          @value = value
        end
      end

      class Constant < Base
        attr_reader :name

        def initialize(name:)
          @name = name
        end
      end
    end

    module Argument
      class Base; end

      class Expr < Base
        attr_reader :expr

        def initialize(expr:)
          @expr = expr
        end
      end

      class KeyValue < Base
        attr_reader :key
        attr_reader :expr

        def initialize(key:, expr:)
          @key = key
          @expr = expr
        end
      end
    end
  end
end
