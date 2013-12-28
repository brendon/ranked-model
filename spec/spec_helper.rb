require 'rubygems'
require 'bundler/setup'

require 'ranked-model'

Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each {|f| require f}

# After the DB connection is setup
require 'database_cleaner'

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

end

RSpec::Matchers.define :define_constant do |expected|
  match { |actual| actual.const_defined?(expected) }
end
