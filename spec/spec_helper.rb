require 'rubygems'
require 'bundler/setup'

require 'ranked-model' # and any other gems you need

Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each {|f| require f}

RSpec.configure do |config|
  config.mock_with :mocha
  config.use_transactional_fixtures = true
end

RSpec::Matchers.define :define_constant do |expected|
  match { |actual| actual.const_defined?(expected) }
end
