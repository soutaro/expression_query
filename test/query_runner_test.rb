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

  def args(script)
    node = Parser::CurrentRuby.parse(script)
    node.children.drop(2)
  end

  def assert_args(script, *args)
    runner = ExpressionQuery::QueryRunner.new(query: nil)
    arg_nodes = args(script)

    result = runner.instance_eval do
      test_args arg_nodes, args
    end

    assert result
  end

  def refute_args(script, *args)
    runner = ExpressionQuery::QueryRunner.new(query: nil)
    arg_nodes = args(script)

    result = runner.instance_eval do
      test_args arg_nodes, args
    end

    refute result
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

    assert_equal 0, select(Q::Expr::Call.new(receiver: Q::Expr::Star.new,
                                             name: :to_s,
                                             args: []),
                           "hello.to_s(1,2,3).size").count
  end

  def test_constant
    assert_equal 1, select(Q::Expr::Constant.new(name: :Foo), "Foo.bar").count
  end

  A = Q::Argument
  E = Q::Expr

  def test_args1
    assert_args "f()"
    refute_args "f(1,2,3)"
    assert_args "f()", A::Any.new
    assert_args "f(1)", A::Any.new
    assert_args "f(1,2,3)", A::Any.new
    assert_args "f(1)", A::Expr.new(expr: E::Literal.new(type: :int))
  end

  def test_hash_args
    # refute_args "f(foo: 1)", A::Any.new
    assert_args "f(foo: 1)", A::KeyValue.new(key: :foo, expr: E::Star.new)
    refute_args "f(foo: 1)", A::KeyValue.new(key: :foo, expr: E::Literal.new(type: :str))
    assert_args "f(foo: 1, bar: 2)", A::KeyValue.new(key: :foo, expr: E::Star.new)
    assert_args "f(x, foo: 1, bar: 2)", A::Expr.new(expr: E::Star.new), A::KeyValue.new(key: :foo, expr: E::Star.new)
  end
end
