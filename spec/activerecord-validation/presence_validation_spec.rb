require 'spec_helper'

describe Musician do
  context 'when model has a validation on the order column' do
    before(:all) do
      Musician.validates :performance_order, :presence => true
    end

    it 'creates instances without error' do
      musician = Musician.create(:name => 'The Beatles')
      expect(musician).to have(0).errors
    end
  end
end
