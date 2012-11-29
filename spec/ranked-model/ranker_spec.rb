require 'spec_helper'

describe RankedModel::Ranker, 'initialized' do

  subject {
    RankedModel::Ranker.new \
      :overview,
      :column    => :a_sorting_column,
      :scope     => :a_scope,
      :with_same => :a_column,
      :class_name => 'SomeClass'
  }

  its(:name) { should == :overview }
  its(:column) { should == :a_sorting_column }
  its(:scope) { should == :a_scope }
  its(:with_same) { should == :a_column }
  its(:class_name) { should == 'SomeClass' }
end
