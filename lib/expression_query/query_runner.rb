module ExpressionQuery
  class QueryRunner
    attr_reader :query

    def initialize(query:)
      @query = query
    end

    #
    # yield(node, parents)
    #
    def run(node, &block)
      run_with_parent(node: node, parent_stack: [], &block)
    end

    private

    def run_with_parent(node:, parent_stack:, &block)
      if test_query node, query
        yield node, parent_stack
      end

      yield_subnodes(node, ancestors: parent_stack) do |node, ancestors|
        run_with_parent(node: node, parent_stack: ancestors, &block)
      end
    end

    def yield_subnodes(node, ancestors:)
      as = [node] + ancestors

      node.children.each do |child|
        if child.is_a?(Parser::AST::Node)
          yield child, as
        end
      end
    end

    def test_query(node, query)
      case query
      when Query::Expr::Star
        true
      when Query::Expr::Question
        true
      when Query::Expr::Underscore
        true
      when Query::Expr::Literal
        test_literal node, query
      when Query::Expr::Call
        node && test_call(node, query)
      end
    end

    def test_call(node, query)
      return false unless node.type == :send
      return false unless node.children[1] == query.name

      receiver = node.children[0]
      return false unless test_query(receiver, query.receiver)

      args = node.children.drop(2)
      test_args(args, query.args)
    end

    def test_args(arg_nodes, arg_queries)
      true
    end

    def test_literal(node, query)
      case query.type
      when :number
        node&.type == :int || node&.type == :float
      else
        node&.type == query.type
      end
    end
  end
end
