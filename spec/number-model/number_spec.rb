require 'spec_helper'

describe Number do

  before {
    200.times do |i|
      Number.create :value => i
    end
  }

  describe "a rearrangement with keyword column name" do

    before {
      @first = Number.first
      @second = Number.offset(1).first
      @ordered = Number.rank(:order).where(Number.arel_table[:id].not_in([@first.id, @second.id])).collect {|d| d.id }
      @first.update_attribute :order, RankedModel::MAX_RANK_VALUE
      @second.update_attribute :order, RankedModel::MAX_RANK_VALUE
    }

    context {

      subject { Number.rank(:order).collect {|d| d.id } }

      it { should == (@ordered[0..-2] + [@ordered[-1], @first.id, @second.id]) }

    }

  end

end
