require 'spec_helper'

describe Vehicle do

  before {
    @vehicles = {
      :ford     => Car.create( :manufacturer => 'Ford' ),
      :bmw      => Car.create( :manufacturer => 'BMW' ),
      :daimler  => Truck.create( :manufacturer => 'Daimler' ),
      :volvo    => Truck.create( :manufacturer => 'Volvo' ),
      :kenworth => Truck.create( :manufacturer => 'Kenworth' )
    }
    @vehicles.each { |name, vehicle|
      vehicle.reload
      vehicle.update_attribute :parking_order_position, 0
    }
    @vehicles.each {|name, vehicle| vehicle.reload }
  }

  describe "ranking by STI parent" do

    before {
      @vehicles[:volvo].update_attribute :parking_order_position, :first
      @vehicles[:ford].update_attribute :parking_order_position, :first
    }

    describe "Vehicle" do

      subject { Vehicle.rank(:parking_order) }

      its(:size) { should == 5 }

      its(:first) { should == @vehicles[:ford] }

      its(:second) { should == @vehicles[:volvo] }

    end

  end

end