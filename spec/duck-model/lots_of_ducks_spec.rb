require 'spec_helper'

describe Duck do

  before {
    200.times do |i|
      Duck.create \
        :name => "Duck #{i}"
    end
  }

  describe "setting and fetching by position" do

    describe '137' do

      before {
        @last = Duck.last
        @last.update_attribute :row_position, 137
      }

      subject { Duck.ranker(:row).with(Duck.new).current_at_position(137).instance }

      its(:id) { should == @last.id }

    end

    describe '2' do

      before {
        @last = Duck.last
        @last.update_attribute :row_position, 2
      }

      subject { Duck.ranker(:row).with(Duck.new).current_at_position(2).instance }

      its(:id) { should == @last.id }

    end

  end

  describe "a rearrangement" do

    describe "with max value" do

      before {
        @first = Duck.first
        @second = Duck.offset(1).first
        @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_in([@first.id, @second.id])).collect {|d| d.id }
        @first.update_attribute :row, RankedModel::MAX_RANK_VALUE
        @second.update_attribute :row, RankedModel::MAX_RANK_VALUE
      }

      context {

        subject { Duck.rank(:row).collect {|d| d.id } }

        it { should == (@ordered[0..-2] + [@first.id, @second.id, @ordered[-1]]) }

      }

    end

    describe "with min value" do

      before {
        @first = Duck.first
        @second = Duck.offset(1).first
        @ordered = Duck.rank(:row).where(Duck.arel_table[:id].not_in([@first.id, @second.id])).collect {|d| d.id }
        @first.update_attribute :row, 0
        @second.update_attribute :row, 0
      }

      context {

        subject { Duck.rank(:row).collect {|d| d.id } }

        it { should == ([@second.id, @first.id] + @ordered) }

      }

    end

    describe "with no more gaps" do

      before {
        @first = Duck.first
        @second = Duck.where(:row => RankedModel::MAX_RANK_VALUE).first || Duck.offset(1).first
        @third = Duck.offset(2).first
        @fourth = Duck.offset(4).first
        @lower = Duck.rank(:row).
          where(Duck.arel_table[:id].not_in([@first.id, @second.id, @third.id, @fourth.id])).
          where(Duck.arel_table[:row].lt(RankedModel::MAX_RANK_VALUE / 2)).
          collect {|d| d.id }
        @upper = Duck.rank(:row).
          where(Duck.arel_table[:id].not_in([@first.id, @second.id, @third.id, @fourth.id])).
          where(Duck.arel_table[:row].gteq(RankedModel::MAX_RANK_VALUE / 2)).
          collect {|d| d.id }
        @first.update_attribute :row, 0
        @second.update_attribute :row, RankedModel::MAX_RANK_VALUE
        @third.update_attribute :row, (RankedModel::MAX_RANK_VALUE / 2)
        @fourth.update_attribute :row, @third.row
      }

      context {

        subject { Duck.rank(:row).collect {|d| d.id } }

        it { should == ([@first.id] + @lower + [@fourth.id, @third.id] + @upper + [@second.id]) }

      }

    end

  end

end
