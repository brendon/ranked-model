require 'spec_helper'

describe RankedModel, '::MAX_RANK_VALUE' do
  it 'should be defined' do
    subject.should be_const_defined(:MAX_RANK_VALUE)
  end

  it 'should be a proc object' do
    RankedModel::MAX_RANK_VALUE.should be_a(Proc)
  end

  context "using postgresql adapter" do
    before { ActiveRecord::Base.connection.stubs(:adapter_name).returns('postgresql') }

    it "should return 4-byte integer maximum" do
      RankedModel::MAX_RANK_VALUE.call.should == 2147483647
    end

  end

  %w(mysql sqlite3).each do |adapter|
    context "using #{adapter} adapter" do
      before { ActiveRecord::Base.connection.stubs(:adapter_name).returns(adapter) }

      it "should return 3-byte integer maximum" do
        RankedModel::MAX_RANK_VALUE.call.should == 8388607
      end
    end
  end
end

describe RankedModel, '::MIN_RANK_VALUE' do
  it 'should be defined' do
    subject.should be_const_defined(:MIN_RANK_VALUE)
  end

  it 'should be a proc object' do
    RankedModel::MIN_RANK_VALUE.should be_a(Proc)
  end

  context "using postgresql adapter" do
    before { ActiveRecord::Base.connection.stubs(:adapter_name).returns('postgresql') }

    it "should return 4-byte integer MINimum" do
      RankedModel::MIN_RANK_VALUE.call.should == -2147483648
    end

  end

  %w(mysql sqlite3).each do |adapter|
    context "using #{adapter} adapter" do
      before { ActiveRecord::Base.connection.stubs(:adapter_name).returns(adapter) }

      it "should return 3-byte integer MINimum" do
        RankedModel::MIN_RANK_VALUE.call.should == -8388607
      end
    end
  end
end
