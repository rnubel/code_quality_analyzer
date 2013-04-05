require 'spec_helper'

describe Analyzer do
  let(:ruby_file) { 
    f = Tempfile.new('rubyfile')
    f.write """class XYZ
        def foo
          a + b + c
        end

        def self.bar(x)
          self.new.foo(x, x, x)
        end
      end
    """
    f.rewind && f
  }

  let(:analyzer) { Analyzer.new }

  context "when analyzing specific files" do
    let(:analysis) { analyzer.analyze_file(ruby_file) }

    it "parses a Ruby file into a CodeFile" do
      analysis.should be_a Analyzer::CodeFile
    end

    describe "the created CodeFile" do
      it "knows the file's path" do
        analysis.path.should =~ /rubyfile/
      end

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
          "        def foo\n" + 
          "          a + b + c\n" +
          "        end\n"
        end

        it "can normalize the method body" do
          method.normalized_lines.should == ["a + b + c"]
        end

        it "outputs an analysis table" do
          method.analysis.should == {
            file_path: analysis.path,
            starting_line: 2,
            raw_length: 3,
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

  context "when analyzing methods with correct line number parsing" do
    let(:code_file) {
      analyzer.analyze_file(File.open(File.expand_path("../support/test2.rb", __FILE__)))
    }
    let(:method) {
      code_file.analyzed_methods.first
    }

    it "parses them correctly" do
      method.normalized_lines.should == ["@x ||= val"]
    end

    it "knows the original location of the method in the source file" do
      method.starting_line.should == 2
      method.raw_length.should == 3
    end
  end
 
  let(:test_files) { File.expand_path("../support/*", __FILE__) }
  let(:test_folder) { File.expand_path("../support", __FILE__) }

  it "parses a folder of files recursively" do
    analyzer.analyze_directory(test_files).size.should == 2
  end

  it "prints out a CSV of the analyzed data" do
    csv = analyzer.collect_data(test_files)
    csv.should have(3).lines
    csv.lines.to_a[1].should == "#{test_folder}/test.rb,2,3,1,9,9,9.0,0\n"
    csv.lines.to_a[2].should == "#{test_folder}/test2.rb,2,3,1,10,10,10.0,0\n"
  end
end
