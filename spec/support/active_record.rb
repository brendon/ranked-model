require 'active_record'
require 'logger'

unless ENV['DB']
  ENV['DB'] = 'sqlite'
end

ActiveRecord::Base.logger = Logger.new('tmp/ar_debug.log')
ActiveRecord::Base.configurations = YAML::load(IO.read('spec/support/database.yml'))
ActiveRecord::Base.establish_connection(ENV['DB'].to_sym)

ActiveRecord::Schema.define :version => 0 do
  create_table :ducks, :force => true do |t|
    t.string :name
    t.integer :row
    t.integer :size
    t.integer :age
    t.integer :lake_id
    t.integer :flock_id
    t.integer :landing_order
    t.string :pond
  end

  add_index :ducks, [:landing_order, :lake_id, :flock_id], unique: true

  create_table :lovesick_ducks, :force => true do |t|
    t.string :name
    t.integer :row
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

  create_table :column_default_ducks, :force => true do |t|
    t.string :name
    t.integer :size, default: 0
    t.string :pond
  end

  create_table :elements, :force => true do |t|
    t.string :symbol
    t.string :type
    t.integer :combination_order
  end

  create_table :vehicles, :force => true do |t|
    t.string :color
    t.string :manufacturer
    t.string :type
    t.integer :parking_order
  end

  create_table :egos, :primary_key => :alternative_to_id, :force => true do |t|
    t.string :name
    t.integer :size
  end

  create_table :players, :force => true do |t|
    t.string :name
    t.string :city
    t.integer :score
  end

  create_table :numbers, :force => true do |t|
    t.float :value
    t.integer :order
  end
end

class Duck < ActiveRecord::Base

  include RankedModel
  ranks :row
  ranks :size, :scope => :in_shin_pond
  ranks :age, :with_same => :pond

  ranks :landing_order, :with_same => [:lake_id, :flock_id]
  scope :in_lake_and_flock, lambda {|lake, flock| where(:lake_id => lake, :flock_id => flock) }

  scope :in_shin_pond, lambda { where(:pond => 'Shin') }

end

class LovesickDuck < ActiveRecord::Base
  include RankedModel
  ranks :row, :preferred_spread => 1000
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

class ReallyWrongFieldDuck < ActiveRecord::Base
  self.table_name = :wrong_field_ducks
  include RankedModel
  ranks :age, :with_same => [:name, :non_existant_field]
end

# Example for STI, ranking within each child class

class Element < ActiveRecord::Base

  include RankedModel
  ranks :combination_order

end

class TransitionMetal < Element

end

class NobleGas < Element

end

# Example for STI, ranking within parent

class Vehicle < ActiveRecord::Base

  include RankedModel
  ranks :parking_order, :class_name => 'Vehicle'

end

class Car < Vehicle

end

class Truck < Vehicle

end

# Example for STI, overriding parent's ranking

class MotorBike < Vehicle

  include RankedModel
  ranks :parking_order, :class_name => 'Vehicle', :with_same => :color

end

class Ego < ActiveRecord::Base
  self.primary_key = :alternative_to_id
  include RankedModel
  ranks :size
end

class Player < ActiveRecord::Base
  # don't add rank yet, do it in the specs
end

class Number < ActiveRecord::Base
  include RankedModel
  ranks :order
end
