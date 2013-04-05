require 'ruby_parser'

class Analyzer
  class CodeMethod
    attr_reader :sexp, :file

    def initialize(sexp, file)
      @file = file
      @sexp = sexp
    end

    def source
      lines = {}
      @sexp.deep_each { |node| lines[node.line] = true }
      file[lines.keys.sort.first, lines.keys.size]
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
