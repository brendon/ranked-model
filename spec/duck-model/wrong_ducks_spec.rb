require 'spec_helper'

describe WrongScopeDuck do

  it "should raise an error because of an unknown scope" do

    expect {
      WrongScopeDuck.create(:name => 'Quocky', :pond => 'Shin')
    }.to raise_error(RankedModel::InvalidScope, 'No scope called "non_existant_scope" found in model')

  end

end

describe WrongFieldDuck do

  it "should raise an error because of an unknown field" do

    expect {
      WrongFieldDuck.create(:name => 'Quicky', :pond => 'Shin')
    }.to raise_error(RankedModel::InvalidField, 'No field called "non_existant_field" found in model')

  end

end
