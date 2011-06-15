require 'active_record'
require 'sqlite3'
require 'logger'
require 'rspec/rails/adapters'
require 'rspec/rails/fixture_support'

ROOT = File.join(File.dirname(__FILE__), '..')

ActiveRecord::Base.logger = Logger.new('tmp/ar_debug.log')
ActiveRecord::Base.configurations = YAML::load(IO.read('spec/support/database.yml'))
ActiveRecord::Base.establish_connection('development')

ActiveRecord::Schema.define :version => 0 do
  create_table :ducks, :force => true do |t|
    t.string :name
    t.integer :row
    t.integer :size
    t.integer :age
    t.string :pond
  end

  create_table :wrong_scope_ducks, :force => true do |t|
    t.string :name
    t.integer :size
    t.string :pond
  end

  create_table :wrong_field_ducks, :force => true do |t|
    t.string :name
    t.integer :age
    t.string :pond
  end

  create_table :elements, :force => true do |t|
    t.string :symbol
    t.string :type
    t.integer :combination_order
  end
end

class Duck < ActiveRecord::Base

  include RankedModel
  ranks :row
  ranks :size, :scope => :in_shin_pond
  ranks :age, :with_same => :pond

  scope :in_shin_pond, where(:pond => 'Shin')

end

# Negative examples

class WrongScopeDuck < ActiveRecord::Base

  include RankedModel
  ranks :size, :scope => :non_existant_scope

end

class WrongFieldDuck < ActiveRecord::Base

  include RankedModel
  ranks :age, :with_same => :non_existant_field

end

class Element < ActiveRecord::Base

  include RankedModel
  ranks :combination_order

end

class TransitionMetal < Element

end

class NobleGas < Element

end
