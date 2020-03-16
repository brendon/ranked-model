require 'spec_helper'

describe Duck do

  before {
    200.times do |i|
      Duck.create \
        :name => "Duck #{i + 1}"
    end
  }

  describe "a large number of records" do
    before { @ducks = Duck.all }

    describe "the last two ducks' rows' difference" do
      subject { @ducks[-1].row - @ducks[-2].row }
      it { is_expected.not_to be_between(-1, 1) }
    end

    describe "the second to last two ducks' rows' difference" do
      subject { @ducks[-2].row - @ducks[-3].row }
      it { is_expected.not_to be_between(-1, 1) }
    end
  end

  describe "setting and fetching by position" do

    describe '137' do

      before {
        @last = Duck.last
        @last.update :row_position => 137
      }

      subject { Duck.ranker(:row).with(Duck.new).current_at_position(137).instance }

      its(:id) { should == @last.id }

    end

    describe '2' do

      before {
        @last = Duck.last
        @last.update :row_position => 2
      }

      subject { Duck.ranker(:row).with(Duck.new).current_at_position(2).instance }

      its(:id) { should == @last.id }

    end

    describe 'last' do

      before {
        @last = Duck.last
        @last.update :row_position => :last
      }

      subject { Duck.rank(:row).last }

      its(:id) { should == @last.id }

    end

    describe 'first' do

      before {
        @last = Duck.last
        @last.update :row_position => :first
      }

      subject { Duck.rank(:row).first }

      its(:id) { should == @last.id }

    end

  end

  describe "a rearrangement" do

    describe "with max value" do

      before {
        @first = Duck.first
        @second = Duck.offset(1).first
        @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_in([@first.id, @second.id])).collect {|d| d.id }
        @first.update :row => RankedModel::MAX_RANK_VALUE
        @second.update :row => RankedModel::MAX_RANK_VALUE
      }

      context {

        subject { Duck.rank(:row).collect {|d| d.id } }

        it { is_expected.to eq(@ordered[0..-2] + [@ordered[-1], @first.id, @second.id]) }

      }

    end

    describe "with max value and with_same pond" do

      before {
        Duck.first(50).each_with_index do |d, index|
          d.update :age => index % 10, :pond => "Pond #{index / 10}"
        end
        @duck_11 = Duck.where(:pond => 'Pond 1').rank(:age).first
        @duck_12 = Duck.where(:pond => 'Pond 1').rank(:age).second
        @ordered = Duck.where(:pond => 'Pond 1').rank(:age).where(Duck.arel_table[:id].not_in([@duck_11.id, @duck_12.id])).collect {|d| d.id }
        @duck_11.update :age => RankedModel::MAX_RANK_VALUE
        @duck_12.update :age => RankedModel::MAX_RANK_VALUE
      }

      context {
        subject { Duck.where(:pond => 'Pond 1').rank(:age).collect {|d| d.id } }

        it { is_expected.to eq(@ordered[0..-2] + [@ordered[-1], @duck_11.id, @duck_12.id]) }
      }

      context {
        subject { Duck.first.age }
        it { is_expected.to eq(0)}
      }
      
    end

    describe "with min value" do

      before {
        @first = Duck.first
        @second = Duck.offset(1).first
        @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_in([@first.id, @second.id])).collect {|d| d.id }
        @first.update :row => RankedModel::MIN_RANK_VALUE
        @second.update :row => RankedModel::MIN_RANK_VALUE
      }

      context {

        subject { Duck.rank(:row).collect {|d| d.id } }

        it { is_expected.to eq([@second.id, @first.id] + @ordered) }

      }

    end

    describe "with no more gaps" do

      before do
        @first = Duck.rank(:row).first
        @second = Duck.rank(:row).offset(1).first
        @third = Duck.rank(:row).offset(2).first
        @fourth = Duck.rank(:row).offset(3).first
        @lower = Duck.rank(:row).
          where(Duck.arel_table[:id].not_in([@first.id, @second.id, @third.id, @fourth.id])).
          where(Duck.arel_table[:row].lt(RankedModel::MAX_RANK_VALUE / 2)).
          pluck(:id)
        @upper = Duck.rank(:row).
          where(Duck.arel_table[:id].not_in([@first.id, @second.id, @third.id, @fourth.id])).
          where(Duck.arel_table[:row].gteq(RankedModel::MAX_RANK_VALUE / 2)).
          pluck(:id)
        @first.update(row: RankedModel::MIN_RANK_VALUE)
        @second.update(row: RankedModel::MAX_RANK_VALUE)
        @third.update(row: (RankedModel::MAX_RANK_VALUE / 2))
        @fourth.update(row: @third.row)
      end

      it 'works correctly' do
        result = Duck.rank(:row).pluck(:id)
        expected = [@first.id, *@lower, @fourth.id, @third.id, *@upper, @second.id]
        expect(result).to eq(expected)
      end

    end

  end

end
