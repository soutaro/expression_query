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
      when Query::Expr::Constant
        node && node.type == :const && node.children[1] == query.name
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
      # p arg_nodes

      while true
        first_node = arg_nodes.first
        first_query = arg_queries.first

        if arg_nodes.empty? || arg_queries.empty?
          return first_query.is_a?(Query::Argument::Any) || arg_nodes.empty? == arg_queries.empty?
        end

        case first_query
        when Query::Argument::Expr
          if first_node && first_node != :hash
            return true
          else
            if first_query.is_a?(Query::Expr::Star)
              arg_nodes.shift
            else
              if test_query(first_node, first_query)
                arg_nodes.shift
                arg_queries.shift
              else
                return false
              end
            end
          end
        when Query::Argument::KeyValue
          if first_node.type == :hash
            if arg_nodes.count == 1
              return test_hash_arg(first_node, arg_queries)
            else
              return false
            end
          else
            return false
          end
        when Query::Argument::Any
          arg_nodes.shift
        else
          p first_node, first_query
          return false
        end
      end
    end

    def test_hash_arg(hash_node, arg_queries)
      hash = hash_node.children.each.with_object({}) {|child, hash|
        return false if child.type != :pair

        key = child.children[0]
        value = child.children[1]

        return false if key.type != :sym

        hash[key.children.first] = value
      }

      arg_queries.all? {|q|
        if q.is_a?(Query::Argument::KeyValue)
          node = hash[q.key]
          !node || test_query(node, q.expr)
        else
          false
        end
      }
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
