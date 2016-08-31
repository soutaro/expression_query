require 'optparse'
require 'pp'

module ExpressionQuery
  class CLI
    attr_reader :args

    def initialize(args)
      @args = args

      OptionParser.new do |opts|
        # TBD
      end.parse!(@args)
    end

    def run
      repo = Repository.new

      FileEnumerator.new(paths: args.map {|arg| Pathname.new(arg) }).each do |path|
        repo.add_script path: path
      end

      query = Query::Expr::Call.new(receiver: Query::Expr::Star.new, name: :transaction, args: [])

      repo.query(query) do |path, node, parents|
        src = node.loc.expression.source.split(/\n/).first
        puts "#{path}:#{node.loc.first_line}\t#{src}"
      end
    end
  end
end
