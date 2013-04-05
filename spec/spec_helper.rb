require File.expand_path('../../lib/analyzer', __FILE__)

require 'tempfile'
require 'pry'

RSpec.configure do |c|
  c.mock_with :mocha
end
