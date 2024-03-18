require 'rubygems'
require 'bundler/setup'
require 'rspec/its'

require 'ranked-model'
require 'pry'

Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each {|f| require f}

RSpec.configure do |config|
  config.mock_with :mocha

  config.around(:each) do |each|
    ActiveRecord::Base.transaction do
      each.run
      raise ActiveRecord::Rollback
    end
  end

  config.order = :random
  Kernel.srand config.seed
end

RSpec::Matchers.define :define_constant do |expected|
  match { |actual| actual.const_defined?(expected) }
end
