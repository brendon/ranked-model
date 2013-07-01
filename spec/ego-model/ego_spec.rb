require 'spec_helper'

describe Ego do

  before {
    @egos = {
      :bob   => Ego.create(:name => 'Bob'),
      :nick  => Ego.create(:name => 'Nick'),
      :sally => Ego.create(:name => 'Sally')
    }
    @egos.each { |name, ego|
      ego.reload
      ego.update_attribute :size_position, 0
      ego.save!
    }
    @egos.each {|name, ego| ego.reload }
  }

  describe "sorting on size alternative primary key" do

    before {
      @egos[:nick].update_attribute :size_position, 0
      @egos[:sally].update_attribute :size_position, 2
    }

    subject { Ego.rank(:size).to_a }

    its(:size) { should == 3 }

    its(:first) { should == @egos[:nick] }

    its(:last) { should == @egos[:sally] }

  end

end
