require 'spec_helper'

describe Duck do

  before {
    @duck = Duck.new
  }

  subject { @duck }

  it { expect(subject).to respond_to(:row_position) }
  it { expect(subject).to respond_to(:row_position=) }
  it { expect(subject).to respond_to(:row_rank) }
  it { expect(subject).to respond_to(:size_position) }
  it { expect(subject).to respond_to(:size_position=) }
  it { expect(subject).to respond_to(:size_rank) }
  it { expect(subject).to respond_to(:age_position) }
  it { expect(subject).to respond_to(:age_position=) }
  it { expect(subject).to respond_to(:age_rank) }
  it { expect(subject).to respond_to(:landing_order_position) }
  it { expect(subject).to respond_to(:landing_order_position=) }
  it { expect(subject).to respond_to(:landing_order_rank) }

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
      duck.update :row_position => 0
      duck.update :size_position => 0
      duck.update :age_position => 0
      duck.save!
    }
    @ducks.each {|name, duck| duck.reload }
  }

  describe "sorting by size on in_shin_pond" do

    before {
      @ducks[:quacky].update :size_position => 0
      @ducks[:wingy].update :size_position => 2
    }

    subject { Duck.in_shin_pond.rank(:size).to_a }

    its(:size) { should == 3 }

    its(:first) { should == @ducks[:quacky] }

    its(:last) { should == @ducks[:wingy] }

  end

  describe "sorting by age on Shin pond" do

    before {
      @ducks[:feathers].update :age_position => 0
      @ducks[:wingy].update :age_position => 0
    }

    subject { Duck.where(:pond => 'Shin').rank(:age).to_a }

    its(:size) { should == 3 }

    its(:first) { should == @ducks[:wingy] }

    its(:last) { should == @ducks[:quacky] }

  end

  describe "sorting by row" do

    before {
      @ducks[:beaky].update :row_position => 0
      @ducks[:webby].update :row_position => 2
      @ducks[:waddly].update :row_position => 2
      @ducks[:wingy].update :row_position => 6
    }

    subject { Duck.rank(:row).to_a }

    its(:size) { should == 6 }

    its(:first) { should == @ducks[:beaky] }

    its(:last) { should == @ducks[:wingy] }

  end

  describe "mixed sorting by" do

    before {
      @ducks[:quacky].update :size_position => 0
      @ducks[:beaky].update :row_position => 0
      @ducks[:webby].update :row_position => 2
      @ducks[:wingy].update :size_position => 1
      @ducks[:waddly].update :row_position => 2
      @ducks[:wingy].update :row_position => 6
      @ducks[:webby].update :row_position => 6
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
      expect(->{
        duck.update :name => 'New Name'
      }).to_not change(duck.reload, :age)
      # puts Duck.rank(:age).collect {|duck| "#{duck.name} #{duck.age}" }
    end

  end

  describe "changing a related attribute" do

    it "marks record as changed" do
      duck = Duck.rank(:age)[2]
      duck.age_position = 1
      expect(duck.changed?).to be true
    end

  end

  describe "setting only truly values" do

    subject { Duck.rank(:age).first }

    it "doesnt set empty string" do
      subject.age_position = ''
      expect(subject.age_position).to be_nil
    end

  end

  describe "setting and fetching by positioning" do

    describe "in the middle" do

      before {
        @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_eq @ducks[:wingy].id).collect {|duck| duck.id }
        @ducks[:wingy].update :row_position => 2
      }

      context {

        subject { Duck.ranker(:row).with(Duck.new).current_at_position(2).instance }

        its(:id) { should == @ducks[:wingy].id }

      }

      context {

        subject { Duck.rank(:row).collect {|duck| duck.id } }

        it { expect(subject[0..1]).to eq(@ordered[0..1]) }

        it { expect(subject[3..subject.length]).to eq(@ordered[2..@ordered.length]) }

      }

    end

    describe "at the start" do

      before {
        @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_eq @ducks[:wingy].id).collect {|duck| duck.id }
        @ducks[:wingy].update :row_position => 0
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

        it { expect(subject[1..subject.length]).to eq(@ordered) }

      }

    end

    describe "second to last" do

      before {
        [:quacky, :feathers, :wingy, :webby, :waddly, :beaky].each_with_index do |name, i|
           Duck.where(id: @ducks[name].id).update_all(row: RankedModel::MAX_RANK_VALUE - i)
           @ducks[name].reload
         end
      }

      context {

        before { @ducks[:wingy].update :row_position => (@ducks.size - 2) }

        subject { Duck.ranker(:row).with(Duck.new).current_at_position(@ducks.size - 2).instance }

        its(:id) { should == @ducks[:wingy].id }

      }

      context {

        before { @ducks[:wingy].update :row_position => :down }

        subject { Duck.ranker(:row).with(Duck.new).current_at_position(@ducks.size - 2).instance }

        its(:id) { should == @ducks[:wingy].id }

      }

    end

    describe "at the end" do

      before {
        @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_eq @ducks[:wingy].id).collect {|duck| duck.id }
        @ducks[:wingy].update :row_position => (@ducks.size - 1)
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

        it { expect(subject[0..-2]).to eq(@ordered) }

      }

    end

    describe "at the end with symbol" do

      before {
        @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_eq @ducks[:wingy].id).collect {|duck| duck.id }
        @ducks[:wingy].update :row_position => :last
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

        it { expect(subject[0..-2]).to eq(@ordered) }

      }

    end

    describe "at the end with string" do

      before {
        @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_eq @ducks[:wingy].id).collect {|duck| duck.id }
        @ducks[:wingy].update :row_position => 'last'
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

        it { expect(subject[0..-2]).to eq(@ordered) }

      }

    end

    describe "down with symbol" do

      context "when in the middle" do

        before {
          @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_eq @ducks[:wingy].id).collect { |duck| duck.id }
          @ducks[:wingy].update :row_position => :down
        }

        context {

          subject { Duck.ranker(:row).with(Duck.new).current_at_position(4).instance }

          its(:id) { should == @ducks[:wingy].id }

        }

        context {

          subject { Duck.rank(:row).collect { |duck| duck.id } }

          it { expect(subject[0..3]).to eq(@ordered[0..3]) }

          it { expect(subject[5..subject.length]).to eq(@ordered[4..@ordered.length]) }

        }

      end

      context "when last" do
        
        before {
          @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_eq @ducks[:quacky].id).collect { |duck| duck.id }
          @ducks[:quacky].update :row_position => :down
        }

        context {

          subject { Duck.ranker(:row).with(Duck.new).current_at_position(@ducks.size - 1).instance }

          its(:id) { should == @ducks[:quacky].id }

        }

        context {

          subject { Duck.rank(:row).collect { |duck| duck.id } }

          it { expect(subject[0..-2]).to eq(@ordered) }

        }

      end

      context "when second last" do
        
        before {
          @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_eq @ducks[:feathers].id).collect { |duck| duck.id }
          @ducks[:feathers].update :row_position => :down
        }

        context {

          subject { Duck.ranker(:row).with(Duck.new).current_at_position(@ducks.size - 1).instance }

          its(:id) { should == @ducks[:feathers].id }

        }

        context {

          subject { Duck.rank(:row).collect { |duck| duck.id } }

          it { expect(subject[0..-2]).to eq(@ordered) }

        }

      end

    end

    describe "down with string" do

      context "when in the middle" do

        before {
          @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_eq @ducks[:wingy].id).collect { |duck| duck.id }
          @ducks[:wingy].update :row_position => 'down'
        }

        context {

          subject { Duck.ranker(:row).with(Duck.new).current_at_position(4).instance }

          its(:id) { should == @ducks[:wingy].id }

        }

        context {

          subject { Duck.rank(:row).collect { |duck| duck.id } }

          it { expect(subject[0..3]).to eq(@ordered[0..3]) }

          it { expect(subject[5..subject.length]).to eq(@ordered[4..@ordered.length]) }

        }

      end

      context "when last" do
        
        before {
          @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_eq @ducks[:quacky].id).collect { |duck| duck.id }
          @ducks[:quacky].update :row_position => 'down'
        }

        context {

          subject { Duck.ranker(:row).with(Duck.new).current_at_position(@ducks.size - 1).instance }

          its(:id) { should == @ducks[:quacky].id }

        }

        context {

          subject { Duck.rank(:row).collect { |duck| duck.id } }

          it { expect(subject[0..-2]).to eq(@ordered) }

        }

      end

      context "when second last" do
        
        before {
          @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_eq @ducks[:feathers].id).collect { |duck| duck.id }
          @ducks[:feathers].update :row_position => 'down'
        }

        context {

          subject { Duck.ranker(:row).with(Duck.new).current_at_position(@ducks.size - 1).instance }

          its(:id) { should == @ducks[:feathers].id }

        }

        context {

          subject { Duck.rank(:row).collect { |duck| duck.id } }

          it { expect(subject[0..-2]).to eq(@ordered) }

        }

      end

    end

    describe "up with symbol" do

      context "when in the middle" do

        before {
          @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_eq @ducks[:wingy].id).collect { |duck| duck.id }
          @ducks[:wingy].update :row_position => :up
        }

        context {

          subject { Duck.ranker(:row).with(Duck.new).current_at_position(2).instance }

          its(:id) { should == @ducks[:wingy].id }

        }

        context {

          subject { Duck.rank(:row).collect { |duck| duck.id } }

          it { expect(subject[0..1]).to eq(@ordered[0..1]) }

          it { expect(subject[3..subject.length]).to eq(@ordered[2..@ordered.length]) }

        }

      end

      context "when first" do
        
        before {
          @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_eq @ducks[:beaky].id).collect { |duck| duck.id }
          @ducks[:beaky].update :row_position => :up
        }

        context {

          subject { Duck.ranker(:row).with(Duck.new).current_at_position(0).instance }

          its(:id) { should == @ducks[:beaky].id }

        }

        context {

          subject { Duck.rank(:row).collect { |duck| duck.id } }

          it { expect(subject[1..subject.length]).to eq(@ordered) }

        }

      end

      context "when second" do
        
        before {
          @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_eq @ducks[:waddly].id).collect { |duck| duck.id }
          @ducks[:waddly].update :row_position => :up
        }

        context {

          subject { Duck.ranker(:row).with(Duck.new).current_at_position(0).instance }

          its(:id) { should == @ducks[:waddly].id }

        }

        context {

          subject { Duck.rank(:row).collect { |duck| duck.id } }

          it { expect(subject[1..subject.length]).to eq(@ordered) }

        }

      end

      context "from position without gaps with rebalance" do

        before {
          [:quacky, :feathers, :wingy, :webby, :waddly, :beaky].each_with_index do |name, i|
            Duck.where(id: @ducks[name].id).update_all(row: i)
            @ducks[name].reload
          end
          @ducks[:wingy].update :row_position => :up
        }

        context {

          subject { Duck.ranker(:row).with(Duck.new).current_at_position(1).instance }

          its(:id) { should == @ducks[:wingy].id }

        }

        context {

          subject { Duck.ranker(:row).with(Duck.new).current_at_position(2).instance }

          its(:id) { should == @ducks[:feathers].id }

        }

      end


    end

    describe "up with string" do

      context "when in the middle" do

        before {
          @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_eq @ducks[:wingy].id).collect { |duck| duck.id }
          @ducks[:wingy].update :row_position => 'up'
        }

        context {

          subject { Duck.ranker(:row).with(Duck.new).current_at_position(2).instance }

          its(:id) { should == @ducks[:wingy].id }

        }

        context {

          subject { Duck.rank(:row).collect { |duck| duck.id } }

          it { expect(subject[0..1]).to eq(@ordered[0..1]) }

          it { expect(subject[3..subject.length]).to eq(@ordered[2..@ordered.length]) }

        }

      end

      context "when first" do
        
        before {
          @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_eq @ducks[:beaky].id).collect { |duck| duck.id }
          @ducks[:beaky].update :row_position => 'up'
        }

        context {

          subject { Duck.ranker(:row).with(Duck.new).current_at_position(0).instance }

          its(:id) { should == @ducks[:beaky].id }

        }

        context {

          subject { Duck.rank(:row).collect { |duck| duck.id } }

          it { expect(subject[1..subject.length]).to eq(@ordered) }

        }

      end

      context "when second" do
        
        before {
          @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_eq @ducks[:waddly].id).collect { |duck| duck.id }
          @ducks[:waddly].update :row_position => 'up'
        }

        context {

          subject { Duck.ranker(:row).with(Duck.new).current_at_position(0).instance }

          its(:id) { should == @ducks[:waddly].id }

        }

        context {

          subject { Duck.rank(:row).collect { |duck| duck.id } }

          it { expect(subject[1..subject.length]).to eq(@ordered) }

        }

      end

    end

  end

  describe "fetching rank for an instance" do
    before {
      [:quacky, :feathers, :wingy, :webby, :waddly, :beaky].each_with_index do |name, i|
         Duck.where(id: @ducks[name].id).update_all(row: RankedModel::MAX_RANK_VALUE - i)
         @ducks[name].reload
      end
    }

    context {
      subject { Duck.find_by(id: @ducks[:beaky]).row_rank }

      it { should == 0 }
    }

    context {
      subject { Duck.find_by(id: @ducks[:wingy]).row_rank }

      it { should == 3 }
    }

    context {
      subject { Duck.find_by(id: @ducks[:quacky]).row_rank }

      it { should == 5 }
    }
  end

  describe "when moving between ponds should work when rebalancing" do
    before do
      [:feathers, :wingy, :webby, :waddly, :beaky].each_with_index do |name, i|
        Duck.where(id: @ducks[name].id)
          .update_all(age: RankedModel::MIN_RANK_VALUE + i, pond: "Boyden")
      end

      @ducks[:quacky].update!(age_position: 2, pond: "Boyden")
    end

    it 'rebalances ranks correctly' do
      expect(@ducks[:feathers].reload.age_rank).to eq 0
      expect(@ducks[:quacky].reload.age_rank).to eq 2
      expect(@ducks[:beaky].reload.age_rank).to eq 5
    end

    context 'when attempting to update position to a non-unique value' do
      before do
        @duck_one = Duck.create(landing_order: RankedModel::MIN_RANK_VALUE,
                               lake_id: 42, flock_id: 42)
        # Duck one's landing order will be rebalanced to -715_827_883.
        # Given a unique index on [:landing_order, :lake_id, :flock_id] we
        # verify that the operation succeeds despite the value already being
        # occupied by duck two.
        @duck_two = Duck.create(landing_order: -715_827_883,
                                lake_id: 42, flock_id: 42)
      end

      it 'rebalances ranks correctly' do
        @ducks[:quacky].update!(landing_order_position: :first,
                                lake_id: 42, flock_id: 42)
        expect(@ducks[:quacky].reload.landing_order_rank).to eq 0
        expect(@duck_one.reload.landing_order_rank).to eq 1
        expect(@duck_two.reload.landing_order_rank).to eq 2
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
      duck.update :landing_order_position => 0
      duck.save!
    }
    @ducks.each {|name, duck| duck.reload }
  }

  describe "sorting by landing_order" do

    before {
      @ducks[:quacky].update :landing_order_position => 0
      @ducks[:wingy].update :landing_order_position => 1
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

      @ducks[:quacky].update :landing_order_position => 0
      @ducks[:wingy].update :landing_order_position => 1
      @ducks[:feathers].update :landing_order_position => 0
      @ducks[:wingy].update :landing_order_position => 1
    }

    subject { @untouchable_ranks.call }

    it { is_expected.to eq(@previous_ranks) }

  end

end
