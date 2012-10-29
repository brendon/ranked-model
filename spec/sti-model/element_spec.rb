require 'spec_helper'

describe Element do

  before {
    @elements = {
      :chromium  => TransitionMetal.create( :symbol => 'Cr' ),
      :manganese => TransitionMetal.create( :symbol => 'Mn' ),
      :argon     => NobleGas.create( :symbol => 'Ar' ),
      :helium    => NobleGas.create( :symbol => 'He' ),
      :xenon     => NobleGas.create( :symbol => 'Xe' )
    }
    @elements.each { |name, element|
      element.reload
      element.update_attribute :combination_order_position, 0
    }
    @elements.each {|name, element| element.reload }
  }

  describe "rebalancing on an STI class should not affect the other class" do

    before {
      @elements[:helium].update_attribute :combination_order_position, :first
      @elements[:xenon].update_attribute :combination_order_position, :first
      @elements[:argon].update_attribute :combination_order_position, :last

      TransitionMetal.ranker(:combination_order).with(@elements[:chromium]).instance_eval { rebalance_ranks }
    }

    subject { NobleGas.rank(:combination_order) }

    its(:size) { should == 3 }

    its(:first) { should == @elements[:xenon] }

    its(:last) { should == @elements[:argon] }

  end

  describe "setting positions on STI classes" do

    before {
      @elements[:helium].update_attribute :combination_order_position, :first
      @elements[:xenon].update_attribute :combination_order_position, :first
      @elements[:argon].update_attribute :combination_order_position, :first

      @elements[:chromium].update_attribute :combination_order_position, 1
      @elements[:manganese].update_attribute :combination_order_position, 1
      @elements[:manganese].update_attribute :combination_order_position, 0
      @elements[:chromium].update_attribute :combination_order_position, 0
      @elements[:manganese].update_attribute :combination_order_position, 0
      @elements[:chromium].update_attribute :combination_order_position, 0
    }

    describe "NobleGas" do

      subject { NobleGas.rank(:combination_order) }

      its(:size) { should == 3 }

      its(:first) { should == @elements[:argon] }

      its(:last) { should == @elements[:helium] }

    end

    describe "TransitionMetal" do

      subject { TransitionMetal.rank(:combination_order) }

      its(:size) { should == 2 }

      its(:first) { should == @elements[:chromium] }

      its(:last) { should == @elements[:manganese] }

    end

  end

  describe "setting positions on STI classes" do

    before {
      @elements[:helium].update_attribute :combination_order_position, :first
      @elements[:xenon].update_attribute :combination_order_position, :first
      @elements[:argon].update_attribute :combination_order_position, :first

      @elements[:chromium].update_attribute :combination_order_position, 1
      @elements[:manganese].update_attribute :combination_order_position, 1
      @elements[:manganese].update_attribute :combination_order_position, 0
      @elements[:chromium].update_attribute :combination_order_position, 0
      @elements[:manganese].update_attribute :combination_order_position, 0
      @elements[:chromium].update_attribute :combination_order_position, 0
    }

    describe "NobleGas" do

      subject { NobleGas.rank(:combination_order) }

      its(:size) { should == 3 }

      its(:first) { should == @elements[:argon] }

      its(:last) { should == @elements[:helium] }

    end

    describe "TransitionMetal" do

      subject { TransitionMetal.rank(:combination_order) }

      its(:size) { should == 2 }

      its(:first) { should == @elements[:chromium] }

      its(:last) { should == @elements[:manganese] }

    end

  end

end
