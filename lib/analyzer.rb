require 'ruby_parser'
require File.expand_path('../enumerable.rb', __FILE__)

class Analyzer
  class CodeMethod
    attr_reader :sexp, :file

    def initialize(sexp, file)
      @file = file
      @sexp = sexp
    end

    def source
      return @source if @source
      lines = {}
      @sexp.deep_each { |node| lines[node.line] = true }
      @source = file[lines.keys.sort.first, lines.keys.size]
    end

    def normalized_lines
      @normalized_lines ||= source.lines.drop(1).reverse.drop(1).reverse.map(&:strip)
    end

    def num_lines
      normalized_lines.count
    end

    def min_line_length
      normalized_lines.map(&:length).min
    end

    def max_line_length
      normalized_lines.map(&:length).min
    end

    def avg_line_length
      normalized_lines.map(&:length).mean
    end

    def line_length_std_dev
      normalized_lines.map(&:length).standard_deviation
    end

    def analysis
      analysis = {}
      %w(num_lines min_line_length max_line_length avg_line_length line_length_std_dev).each do |k|
        analysis[k.to_sym] = self.send(k)
      end

      return analysis
    end
  end

  class CodeFile
    attr_reader :sexp

    def initialize(stream)
      @contents = stream.read
      @sexp     = RubyParser.new.parse(@contents)
    end

    def [](start, length)
      @contents.lines.drop(start - 1).take(length + 1).join
    end

    def analyzed_methods
      methods = []
      @sexp.deep_each do |node|
        methods << CodeMethod.new(node, self) if [:defn, :defs].include? node.node_type
      end

      methods
    end
  end

  def analyze_file(file)
    CodeFile.new(file)
  end
end
