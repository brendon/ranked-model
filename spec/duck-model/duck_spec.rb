require 'spec_helper'

describe Duck do

  before {
    @duck = Duck.new
  }

  subject { @duck }

  it { subject.respond_to?(:row_position).should be_true }
  it { subject.respond_to?(:row_position=).should be_true }
  it { subject.respond_to?(:size_position).should be_true }
  it { subject.respond_to?(:size_position=).should be_true }
  it { subject.respond_to?(:age_position).should be_true }
  it { subject.respond_to?(:age_position=).should be_true }
  it { subject.respond_to?(:landing_order_position).should be_true }
  it { subject.respond_to?(:landing_order_position=).should be_true }

end

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

    subject { Duck.in_shin_pond.rank(:size).to_a }

    its(:size) { should == 3 }

    its(:first) { should == @ducks[:quacky] }

    its(:last) { should == @ducks[:wingy] }

  end

  describe "sorting by age on Shin pond" do

    before {
      @ducks[:feathers].update_attribute :age_position, 0
      @ducks[:wingy].update_attribute :age_position, 0
    }

    subject { Duck.where(:pond => 'Shin').rank(:age).to_a }

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

    subject { Duck.rank(:row).to_a }

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

      subject { Duck.rank(:row).to_a }

      its(:size) { should == 6 }

      its(:first) { should == @ducks[:beaky] }

      its(:last) { should == @ducks[:webby] }

    end

    describe "row" do

      subject { Duck.in_shin_pond.rank(:size).to_a }

      its(:size) { should == 3 }

      its(:first) { should == @ducks[:quacky] }

      its(:last) { should == @ducks[:feathers] }

    end

  end

  describe "changing an unrelated attribute" do

    it "doesn't change ranking" do
      # puts Duck.rank(:age).collect {|duck| "#{duck.name} #{duck.age}" }
      duck = Duck.rank(:age)[2]
      ->{
        duck.update_attribute :name, 'New Name'
      }.should_not change(duck.reload, :age)
      # puts Duck.rank(:age).collect {|duck| "#{duck.name} #{duck.age}" }
    end

  end

  describe "changing a related attribute" do

    it "marks record as changed" do
      duck = Duck.rank(:age)[2]
      duck.age_position = 1
      duck.changed?.should be_true
    end

  end

  describe "setting only truly values" do

    subject { Duck.rank(:age).first }

    it "doesnt set empty string" do
      subject.age_position = ''
      subject.age_position.should be_nil
    end

  end

  describe "setting and fetching by positioning" do

    describe "in the middle" do

      before {
        @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_eq @ducks[:wingy].id).collect {|duck| duck.id }
        @ducks[:wingy].update_attribute :row_position, 2
      }

      context {

        subject { Duck.ranker(:row).with(Duck.new).current_at_position(2).instance }

        its(:id) { should == @ducks[:wingy].id }

      }

      context {

        subject { Duck.rank(:row).collect {|duck| duck.id } }

        it { subject[0..1].should == @ordered[0..1] }

        it { subject[3..subject.length].should == @ordered[2..@ordered.length] }

      }

    end

    describe "at the start" do

      before {
        @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_eq @ducks[:wingy].id).collect {|duck| duck.id }
        @ducks[:wingy].update_attribute :row_position, 0
      }

      context {

        subject { Duck.ranker(:row).with(Duck.new).current_at_position(0).instance }

        its(:id) { should == @ducks[:wingy].id }

      }

      context {

        subject { Duck.ranker(:row).with(Duck.new).instance_eval { current_first }.instance }

        its(:id) { should == @ducks[:wingy].id }

      }

      context {

        subject { Duck.rank(:row).collect {|duck| duck.id } }

        it { subject[1..subject.length].should == @ordered }

      }

    end

    describe "at the end" do

      before {
        @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_eq @ducks[:wingy].id).collect {|duck| duck.id }
        @ducks[:wingy].update_attribute :row_position, (@ducks.size - 1)
      }

      context {

        subject { Duck.ranker(:row).with(Duck.new).current_at_position(@ducks.size - 1).instance }

        its(:id) { should == @ducks[:wingy].id }

      }

      context {

        subject { Duck.rank(:row).last }

        its(:id) { should == @ducks[:wingy].id }

      }

      context {

        subject { Duck.ranker(:row).with(Duck.new).instance_eval { current_last }.instance }

        its(:id) { should == @ducks[:wingy].id }

      }

      context {

        subject { Duck.rank(:row).collect {|duck| duck.id } }

        it { subject[0..-2].should == @ordered }

      }

    end

    describe "at the end with symbol" do

      before {
        @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_eq @ducks[:wingy].id).collect {|duck| duck.id }
        @ducks[:wingy].update_attribute :row_position, :last
      }

      context {

        subject { Duck.ranker(:row).with(Duck.new).current_at_position(@ducks.size - 1).instance }

        its(:id) { should == @ducks[:wingy].id }

      }

      context {

        subject { Duck.rank(:row).last }

        its(:id) { should == @ducks[:wingy].id }

      }

      context {

        subject { Duck.ranker(:row).with(Duck.new).instance_eval { current_last }.instance }

        its(:id) { should == @ducks[:wingy].id }

      }

      context {

        subject { Duck.rank(:row).collect {|duck| duck.id } }

        it { subject[0..-2].should == @ordered }

      }

    end

    describe "at the end with string" do

      before {
        @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_eq @ducks[:wingy].id).collect {|duck| duck.id }
        @ducks[:wingy].update_attribute :row_position, 'last'
      }

      context {

        subject { Duck.ranker(:row).with(Duck.new).current_at_position(@ducks.size - 1).instance }

        its(:id) { should == @ducks[:wingy].id }

      }

      context {

        subject { Duck.rank(:row).last }

        its(:id) { should == @ducks[:wingy].id }

      }

      context {

        subject { Duck.ranker(:row).with(Duck.new).instance_eval { current_last }.instance }

        its(:id) { should == @ducks[:wingy].id }

      }

      context {

        subject { Duck.rank(:row).collect {|duck| duck.id } }

        it { subject[0..-2].should == @ordered }

      }

    end

    describe "down with symbol" do

      context "when in the middle" do

        before {
          @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_eq @ducks[:wingy].id).collect { |duck| duck.id }
          @ducks[:wingy].update_attribute :row_position, :down
        }

        context {

          subject { Duck.ranker(:row).with(Duck.new).current_at_position(4).instance }

          its(:id) { should == @ducks[:wingy].id }

        }

        context {

          subject { Duck.rank(:row).collect { |duck| duck.id } }

          it { subject[0..3].should == @ordered[0..3] }

          it { subject[5..subject.length].should == @ordered[4..@ordered.length] }

        }

      end

      context "when last" do
        
        before {
          @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_eq @ducks[:quacky].id).collect { |duck| duck.id }
          @ducks[:quacky].update_attribute :row_position, :down
        }

        context {

          subject { Duck.ranker(:row).with(Duck.new).current_at_position(@ducks.size - 1).instance }

          its(:id) { should == @ducks[:quacky].id }

        }

        context {

          subject { Duck.rank(:row).collect { |duck| duck.id } }

          it { subject[0..-2].should eq(@ordered) }

        }

      end

      context "when second last" do
        
        before {
          @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_eq @ducks[:feathers].id).collect { |duck| duck.id }
          @ducks[:feathers].update_attribute :row_position, :down
        }

        context {

          subject { Duck.ranker(:row).with(Duck.new).current_at_position(@ducks.size - 1).instance }

          its(:id) { should == @ducks[:feathers].id }

        }

        context {

          subject { Duck.rank(:row).collect { |duck| duck.id } }

          it { subject[0..-2].should eq(@ordered) }

        }

      end

    end

    describe "down with string" do

      context "when in the middle" do

        before {
          @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_eq @ducks[:wingy].id).collect { |duck| duck.id }
          @ducks[:wingy].update_attribute :row_position, 'down'
        }

        context {

          subject { Duck.ranker(:row).with(Duck.new).current_at_position(4).instance }

          its(:id) { should == @ducks[:wingy].id }

        }

        context {

          subject { Duck.rank(:row).collect { |duck| duck.id } }

          it { subject[0..3].should == @ordered[0..3] }

          it { subject[5..subject.length].should == @ordered[4..@ordered.length] }

        }

      end

      context "when last" do
        
        before {
          @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_eq @ducks[:quacky].id).collect { |duck| duck.id }
          @ducks[:quacky].update_attribute :row_position, 'down'
        }

        context {

          subject { Duck.ranker(:row).with(Duck.new).current_at_position(@ducks.size - 1).instance }

          its(:id) { should == @ducks[:quacky].id }

        }

        context {

          subject { Duck.rank(:row).collect { |duck| duck.id } }

          it { subject[0..-2].should eq(@ordered) }

        }

      end

      context "when second last" do
        
        before {
          @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_eq @ducks[:feathers].id).collect { |duck| duck.id }
          @ducks[:feathers].update_attribute :row_position, 'down'
        }

        context {

          subject { Duck.ranker(:row).with(Duck.new).current_at_position(@ducks.size - 1).instance }

          its(:id) { should == @ducks[:feathers].id }

        }

        context {

          subject { Duck.rank(:row).collect { |duck| duck.id } }

          it { subject[0..-2].should eq(@ordered) }

        }

      end

    end

    describe "up with symbol" do

      context "when in the middle" do

        before {
          @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_eq @ducks[:wingy].id).collect { |duck| duck.id }
          @ducks[:wingy].update_attribute :row_position, :up
        }

        context {

          subject { Duck.ranker(:row).with(Duck.new).current_at_position(2).instance }

          its(:id) { should == @ducks[:wingy].id }

        }

        context {

          subject { Duck.rank(:row).collect { |duck| duck.id } }

          it { subject[0..1].should == @ordered[0..1] }

          it { subject[3..subject.length].should == @ordered[2..@ordered.length] }

        }

      end

      context "when first" do
        
        before {
          @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_eq @ducks[:beaky].id).collect { |duck| duck.id }
          @ducks[:beaky].update_attribute :row_position, :up
        }

        context {

          subject { Duck.ranker(:row).with(Duck.new).current_at_position(0).instance }

          its(:id) { should == @ducks[:beaky].id }

        }

        context {

          subject { Duck.rank(:row).collect { |duck| duck.id } }

          it { subject[1..subject.length].should eq(@ordered) }

        }

      end

      context "when second" do
        
        before {
          @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_eq @ducks[:waddly].id).collect { |duck| duck.id }
          @ducks[:waddly].update_attribute :row_position, :up
        }

        context {

          subject { Duck.ranker(:row).with(Duck.new).current_at_position(0).instance }

          its(:id) { should == @ducks[:waddly].id }

        }

        context {

          subject { Duck.rank(:row).collect { |duck| duck.id } }

          it { subject[1..subject.length].should eq(@ordered) }

        }

      end

    end

    describe "up with string" do

      context "when in the middle" do

        before {
          @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_eq @ducks[:wingy].id).collect { |duck| duck.id }
          @ducks[:wingy].update_attribute :row_position, 'up'
        }

        context {

          subject { Duck.ranker(:row).with(Duck.new).current_at_position(2).instance }

          its(:id) { should == @ducks[:wingy].id }

        }

        context {

          subject { Duck.rank(:row).collect { |duck| duck.id } }

          it { subject[0..1].should == @ordered[0..1] }

          it { subject[3..subject.length].should == @ordered[2..@ordered.length] }

        }

      end

      context "when first" do
        
        before {
          @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_eq @ducks[:beaky].id).collect { |duck| duck.id }
          @ducks[:beaky].update_attribute :row_position, 'up'
        }

        context {

          subject { Duck.ranker(:row).with(Duck.new).current_at_position(0).instance }

          its(:id) { should == @ducks[:beaky].id }

        }

        context {

          subject { Duck.rank(:row).collect { |duck| duck.id } }

          it { subject[1..subject.length].should eq(@ordered) }

        }

      end

      context "when second" do
        
        before {
          @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_eq @ducks[:waddly].id).collect { |duck| duck.id }
          @ducks[:waddly].update_attribute :row_position, 'up'
        }

        context {

          subject { Duck.ranker(:row).with(Duck.new).current_at_position(0).instance }

          its(:id) { should == @ducks[:waddly].id }

        }

        context {

          subject { Duck.rank(:row).collect { |duck| duck.id } }

          it { subject[1..subject.length].should eq(@ordered) }

        }

      end

    end

  end

end

describe Duck do

  before {
    @ducks = {
      :quacky => Duck.create(
        :name => 'Quacky',
        :lake_id => 0,
        :flock_id => 0 ),
      :feathers => Duck.create(
        :name => 'Feathers',
        :lake_id => 0,
        :flock_id => 0 ),
      :wingy => Duck.create(
        :name => 'Wingy',
        :lake_id => 0,
        :flock_id => 0 ),
      :webby => Duck.create(
        :name => 'Webby',
        :lake_id => 1,
        :flock_id => 1 ),
      :waddly => Duck.create(
        :name => 'Waddly',
        :lake_id => 1,
        :flock_id => 0 ),
      :beaky => Duck.create(
        :name => 'Beaky',
        :lake_id => 0,
        :flock_id => 1 ),
    }
    @ducks.each { |name, duck|
      duck.reload
      duck.update_attribute :landing_order_position, 0
      duck.save!
    }
    @ducks.each {|name, duck| duck.reload }
  }

  describe "sorting by landing_order" do

    before {
      @ducks[:quacky].update_attribute :landing_order_position, 0
      @ducks[:wingy].update_attribute :landing_order_position, 1
    }

    subject { Duck.in_lake_and_flock(0,0).rank(:landing_order).to_a }

    its(:size) { should == 3 }

    its(:first) { should == @ducks[:quacky] }

    its(:last) { should == @ducks[:feathers] }

  end

  describe "sorting by landing_order doesn't touch other items" do

    before {
      @untouchable_ranks = lambda {
        [:webby, :waddly, :beaky].inject([]) do |ranks, untouchable_duck|
          ranks << @ducks[untouchable_duck].landing_order
        end
      }

      @previous_ranks = @untouchable_ranks.call

      @ducks[:quacky].update_attribute :landing_order_position, 0
      @ducks[:wingy].update_attribute :landing_order_position, 1
      @ducks[:feathers].update_attribute :landing_order_position, 0
      @ducks[:wingy].update_attribute :landing_order_position, 1
    }

    subject { @untouchable_ranks.call }

    it { should == @previous_ranks }

  end

end
