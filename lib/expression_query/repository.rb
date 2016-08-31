module ExpressionQuery
  class Repository
    attr_reader :scripts

    def initialize
      @scripts = {}
    end

    def add_script(path:, script: nil)
      node = Parser::CurrentRuby.parse(script || path.read, path.to_s)
      @scripts[path] = node
    end

    #
    # select(query) do |path, node, parents|
    #   ...
    # end
    #
    def query(query)
      runner = QueryRunner.new(query: query)

      scripts.each do |path, node|
        runner.run(node) do |node, parents|
          yield path, node, parents
        end
      end
    end
  end
end
