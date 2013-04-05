require 'spec_helper'

describe Analyzer do
  let(:ruby_file) { 
    f = Tempfile.new('rubyfile')
    f.write """
      class XYZ
        def foo(a, b, c)
          a + b + c
        end

        def self.bar(x)
          self.new.foo(x, x, x)
        end
      end
    """
    f.rewind && f
  }

  context "when analyzing specific files" do
    let(:analysis) { Analyzer.new.analyze_file(ruby_file) }

    it "parses a Ruby file into a CodeFile" do
      analysis.should be_a Analyzer::CodeFile
    end

    describe "the created CodeFile" do
      it "has an enumeration of every method defined in that file" do
        expect(analysis).to have(2).analyzed_methods
      end

      describe "has the analyzed methods, each of which" do
        let(:method) { analysis.analyzed_methods.first }

        it "has the parsed sexp of the method" do
          method.sexp.should be_a Sexp
        end

        it "knows the relevant source code" do
          method.source.should == 
          "        def foo(a, b, c)\n" + 
          "          a + b + c\n" +
          "        end\n"
        end

        it "can normalize the method body" do
          method.normalized_lines.should == ["a + b + c"]
        end

        it "outputs an analysis table" do
          method.analysis.should == {
            num_lines: 1,
            min_line_length: 9,
            max_line_length: 9,
            avg_line_length: 9.0,
            line_length_std_dev: 0
          }
        end
      end
    end
  end
  
  it "parses a folder of files recursively" do
    pending
  end

  it "prints out a CSV of the analyzed data" do
    pending
  end
end
