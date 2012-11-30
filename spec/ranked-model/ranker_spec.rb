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
