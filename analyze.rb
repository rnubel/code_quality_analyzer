$:.push(File.expand_path('../lib', __FILE__))
require 'analyzer'

if __FILE__ == $0
  puts Analyzer.new.collect_data(File.join(ARGV.first, "**", "*.rb"))
end
