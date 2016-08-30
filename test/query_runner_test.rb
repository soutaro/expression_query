require_relative 'test_helper'

class QueryRunnerTest < Minitest::Test
  Q = ExpressionQuery::Query

  def select(query, script)
    if block_given?
      node = Parser::CurrentRuby.parse(script)
      runner = ExpressionQuery::QueryRunner.new(query: query)

      runner.run(node) do |selected_node, parents|
        yield selected_node, parents, node
      end
    else
      enum_for :select, query, script
    end
  end

  def test_star
    query = Q::Expr::Star.new

    assert_equal 3, select(query, "1+2").count
  end

  def test_literal
    assert_equal 2, select(Q::Expr::Literal.new(type: :int), "1+2").count
    assert_equal 1, select(Q::Expr::Literal.new(type: :float), "1.0 + x").count
    assert_equal 2, select(Q::Expr::Literal.new(type: :number), "1.0 + 2").count
    assert_equal 1, select(Q::Expr::Literal.new(type: :str), '"foo".bar').count
    assert_equal 1, select(Q::Expr::Literal.new(type: :sym), ":foo.to_s").count
    assert_equal 1, select(Q::Expr::Literal.new(type: :array), "[].each").count
    assert_equal 1, select(Q::Expr::Literal.new(type: :hash), "{}.size").count
  end

  def test_call
    assert_equal 1, select(Q::Expr::Call.new(receiver: Q::Expr::Star.new,
                                             name: :to_s,
                                             args: []),
                           "hello.to_s.size").count

    assert_equal 1, select(Q::Expr::Call.new(receiver: Q::Expr::Star.new,
                                             name: :to_s,
                                             args: []),
                           "hello.to_s(1,2,3).size").count
  end
end
