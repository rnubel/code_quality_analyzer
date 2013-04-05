require 'csv'
require 'highline'
require 'highline/import'

csv = CSV.new(File.read(ARGV.first))

labels = csv.drop(1).collect do |line|
  puts "------"
  puts File.read(line[0]).lines.to_a[line[1].to_i, line[2].to_i]
  puts "------"
  ask("Classify as?")
end

puts labels.join(",")
