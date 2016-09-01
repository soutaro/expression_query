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

      # save(validate: false)
      # query = Query::Expr::Call.new(receiver: Query::Expr::Star.new,
      #                               name: :save,
      #                               args: [Query::Argument::KeyValue.new(
      #                                 key: :validate,
      #                                 expr: Query::Expr::Star.new
      #                               )])

      # delete_all
      # query = Query::Expr::Call.new(receiver: Query::Expr::Star.new,
      #                               name: :delete_all,
      #                               args: [])

      # unscoped
      # query = Query::Expr::Call.new(receiver: Query::Expr::Star.new,
      #                               name: :unscoped,
      #                               args: [])

      # File.open
      query = Query::Expr::Call.new(receiver: Query::Expr::Constant.new(name: :File),
                                    name: :open,
                                    args: [Query::Argument::Any.new])

      # Pathname.new
      # query = Query::Expr::Call.new(receiver: Query::Expr::Constant.new(name: :Pathname),
      #                               name: :new,
      #                               args: [Query::Argument::Any.new])
      
      repo.query(query) do |path, node, parents|
        src = node.loc.expression.source.split(/\n/).first
        puts "#{path}:#{node.loc.first_line}\t#{src}"
      end
    end
  end
end
