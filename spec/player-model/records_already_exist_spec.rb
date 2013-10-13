require 'spec_helper'

describe Player do

  before {
    @players = {}
    @players[:dave] = Player.create!(:name => "Dave", :city => "Detroit")
    @players[:bob] = Player.create!(:name => "Bob", :city => "Portland")
    @players[:nigel] = Player.create!(:name => "Nigel", :city => "New York")
    Player.class_eval do
      include RankedModel
      ranks :score
    end

  }

  describe "setting the position of a record that already exists" do
    it "sets the rank without error" do
      expect{@players[:bob].update_attributes! :score_position => 1}.to_not raise_error
    end
  end
end
