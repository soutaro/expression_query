require 'pathname'
require 'parser/current'

Parser::Builders::Default.emit_lambda = true

require "expression_query/version"
require 'expression_query/query'
require 'expression_query/repository'
require 'expression_query/query_runner'
require 'expression_query/file_enumerator'
