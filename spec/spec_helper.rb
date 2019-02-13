require 'rubygems'
require 'bundler/setup'
require 'rspec/its'

require 'ranked-model'
require 'pry'

Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each {|f| require f}

# After the DB connection is setup
require 'database_cleaner'

# Uncomment this to see Active Record logging for tests
# ActiveRecord::Base.logger = Logger.new(STDOUT)

RSpec.configure do |config|
  config.mock_with :mocha

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  config.order = :random
  Kernel.srand config.seed
end

RSpec::Matchers.define :define_constant do |expected|
  match { |actual| actual.const_defined?(expected) }
end
