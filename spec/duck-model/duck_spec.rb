require 'spec_helper'

describe Duck do

  before {
    @ducks = {
      :quacky => Duck.create(
        :name => 'Quacky',
        :pond => 'Shin' ),
      :feathers => Duck.create(
        :name => 'Feathers',
        :pond => 'Shin' ),
      :wingy => Duck.create(
        :name => 'Wingy',
        :pond => 'Shin' ),
      :webby => Duck.create(
        :name => 'Webby',
        :pond => 'Boyden' ),
      :waddly => Duck.create(
        :name => 'Waddly',
        :pond => 'Meddybemps' ),
      :beaky => Duck.create(
        :name => 'Beaky',
        :pond => 'Great Moose' )
    }
    @ducks.each { |name, duck|
      duck.reload
      duck.update_attribute :row_position, 0
      duck.update_attribute :size_position, 0
      duck.update_attribute :age_position, 0
      duck.save!
    }
    @ducks.each {|name, duck| duck.reload }
  }

  describe "sorting by size on in_shin_pond" do

    before {
      @ducks[:quacky].update_attribute :size_position, 0
      @ducks[:wingy].update_attribute :size_position, 2
    }

    subject { Duck.in_shin_pond.rank(:size).all }

    its(:size) { should == 3 }
    
    its(:first) { should == @ducks[:quacky] }
    
    its(:last) { should == @ducks[:wingy] }

  end

  describe "sorting by age on Shin pond" do

    before {
      @ducks[:feathers].update_attribute :age_position, 0
      @ducks[:wingy].update_attribute :age_position, 0
    }

    subject { Duck.where(:pond => 'Shin').rank(:age).all }

    its(:size) { should == 3 }
    
    its(:first) { should == @ducks[:wingy] }
    
    its(:last) { should == @ducks[:quacky] }

  end

  describe "sorting by row" do

    before {
      @ducks[:beaky].update_attribute :row_position, 0
      @ducks[:webby].update_attribute :row_position, 2
      @ducks[:waddly].update_attribute :row_position, 2
      @ducks[:wingy].update_attribute :row_position, 6
    }

    subject { Duck.rank(:row).all }

    its(:size) { should == 6 }
    
    its(:first) { should == @ducks[:beaky] }
    
    its(:last) { should == @ducks[:wingy] }

  end

  describe "mixed sorting by" do

    before {
      @ducks[:quacky].update_attribute :size_position, 0
      @ducks[:beaky].update_attribute :row_position, 0
      @ducks[:webby].update_attribute :row_position, 2
      @ducks[:wingy].update_attribute :size_position, 1
      @ducks[:waddly].update_attribute :row_position, 2
      @ducks[:wingy].update_attribute :row_position, 6
      @ducks[:webby].update_attribute :row_position, 6
    }

    describe "row" do 

      subject { Duck.rank(:row).all }

      its(:size) { should == 6 }
      
      its(:first) { should == @ducks[:beaky] }
      
      its(:last) { should == @ducks[:webby] }

    end

    describe "row" do 

      subject { Duck.in_shin_pond.rank(:size).all }

      its(:size) { should == 3 }
      
      its(:first) { should == @ducks[:quacky] }
      
      its(:last) { should == @ducks[:feathers] }

    end

  end

end
