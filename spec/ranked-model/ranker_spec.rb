require 'spec_helper'

describe RankedModel::Ranker, 'initialized' do

  subject {
    RankedModel::Ranker.new \
      :overview,
      :column     => :a_sorting_column,
      :scope      => :a_scope,
      :with_same  => :a_column,
      :class_name => 'SomeClass',
      :unless     => :a_method
  }

  its(:name) { should == :overview }
  its(:column) { should == :a_sorting_column }
  its(:scope) { should == :a_scope }
  its(:with_same) { should == :a_column }
  its(:class_name) { should == 'SomeClass' }
  its(:unless) { should == :a_method }
end

describe RankedModel::Ranker, 'unless as Symbol' do
  let(:receiver) { mock('model') }

  subject {
    RankedModel::Ranker.new(:overview, :unless => :a_method).with(receiver)
  }

  context 'returns true' do
    before { receiver.expects(:a_method).once.returns(true) }

    its(:handle_ranking) { should == nil }
  end

  context 'returns false' do
    before { receiver.expects(:a_method).once.returns(false) }

    it {
      subject.expects(:update_index_from_position).once
      subject.expects(:assure_unique_position).once

      subject.handle_ranking
    }
  end
end

describe RankedModel::Ranker, 'unless as Proc' do
  context 'returns true' do
    subject { RankedModel::Ranker.new(:overview, :unless => Proc.new { true }).with(Class.new) }
    its(:handle_ranking) { should == nil }
  end

  context 'returns false' do
    subject { RankedModel::Ranker.new(:overview, :unless => Proc.new { false }).with(Class.new) }

    it {
      subject.expects(:update_index_from_position).once
      subject.expects(:assure_unique_position).once

      subject.handle_ranking
    }
  end
end

describe RankedModel::Ranker, 'unless as lambda' do
  context 'returns true' do
    subject { RankedModel::Ranker.new(:overview, unless: ->(_) { true }).with(Class.new) }
    its(:handle_ranking) { should == nil }
  end

  context 'returns false' do
    subject { RankedModel::Ranker.new(:overview, unless: ->(_) { false }).with(Class.new) }

    it {
      subject.expects(:update_index_from_position).once
      subject.expects(:assure_unique_position).once

      subject.handle_ranking
    }
  end
end

# rebalance_ranks should keep all ranks within bounds
# see: https://github.com/brendon/ranked-model/issues/206
describe RankedModel::Ranker::Mapper, "rebalance_ranks" do
  around do |example|
    original_min = RankedModel::MIN_RANK_VALUE
    original_max = RankedModel::MAX_RANK_VALUE
    RankedModel.send(:remove_const, :MIN_RANK_VALUE)
    RankedModel.send(:remove_const, :MAX_RANK_VALUE)
    RankedModel.const_set(:MIN_RANK_VALUE, -256)
    RankedModel.const_set(:MAX_RANK_VALUE, 255)
    example.run
  ensure
    RankedModel.send(:remove_const, :MIN_RANK_VALUE)
    RankedModel.send(:remove_const, :MAX_RANK_VALUE)
    RankedModel.const_set(:MIN_RANK_VALUE, original_min)
    RankedModel.const_set(:MAX_RANK_VALUE, original_max)
  end

  it "keeps all ranks within bounds after rebalancing" do
    27.times { |i| Duck.create(name: "Duck #{i}") }
    duck = Duck.first

    Duck.ranker(:row).with(duck).instance_eval { rebalance_ranks }

    ranks = Duck.pluck(:row)
    expect(ranks.max).to be <= RankedModel::MAX_RANK_VALUE
    expect(ranks.min).to be >= RankedModel::MIN_RANK_VALUE
  end
end