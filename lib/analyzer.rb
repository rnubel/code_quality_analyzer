require 'ruby_parser'
require 'csv'
require File.expand_path('../enumerable.rb', __FILE__)

class Analyzer
  ANALYZED_PROPERTIES = %w(file_path starting_line raw_length num_lines min_line_length max_line_length avg_line_length line_length_std_dev)

  class CodeMethod
    attr_reader :sexp, :file, :source, :starting_line, :raw_length

    def initialize(sexp, file)
      @file = file
      @sexp = sexp
      fetch_source!
    end

    def fetch_source!
      lines = {}
      @sexp.deep_each { |node| lines[node.line] = true }
      line_numbers = lines.keys.sort
      first_line = line_numbers.first
      length     = line_numbers.length + 1

      # Sometimes line numbers miss the def line, sometimes they don't.
      if file[first_line] !~ /^\s*def/
        first_line -= 1
        length += 1
      end

      @starting_line = first_line
      @raw_length = length
      @source = file[first_line, length]
    end

    def file_path
      file.path
    end

    def normalized_lines
      @normalized_lines ||= source.lines.reject { |l|
        l =~ /^\s*(def|end\s*$)/
      }.map(&:strip)
    end

    def line_lengths
      normalized_lines.map(&:length)
    end

    def num_lines
      normalized_lines.count
    end

    def min_line_length
      line_lengths.min
    end

    def max_line_length
      line_lengths.min
    end

    def avg_line_length
      line_lengths.mean
    end

    def line_length_std_dev
      line_lengths.standard_deviation
    end

    def analysis
      analysis = {}
      ANALYZED_PROPERTIES.each do |k|
        analysis[k.to_sym] = self.send(k)
      end

      return analysis
    end
  end

  class CodeFile
    attr_reader :sexp, :path

    def initialize(stream)
      @contents = stream.read
      @path = stream.path rescue nil
      @sexp     = RubyParser.new.parse(@contents)
    end

    def [](start, length=1)
      @contents.lines.drop(start - 1).take(length).join
    end

    def analyzed_methods
      methods = []
      @sexp.deep_each do |node|
        methods << CodeMethod.new(node, self) if [:defn, :defs].include? node.node_type
      end

      methods
    end

    def method_analyses
      analyzed_methods.map(&:analysis)
    end
  end

  def analyze_file(file)
    CodeFile.new(file)
  end

  def analyze_directory(dir_spec)
    Dir[dir_spec].collect { |f|
      analyze_file(File.open(f))
    }
  end

  def collect_data(path)
    file = CSV.generate do |csv|
      csv << ANALYZED_PROPERTIES
      analyze_directory(path).map(&:method_analyses).flatten.each do |analysis|
        csv << analysis.values
      end
    end
  end
end

