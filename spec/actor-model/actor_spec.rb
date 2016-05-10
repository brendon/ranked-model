require 'spec_helper'

describe Player do

  before {
    @actors = {}
    @actors[:doctor] = Actor.create!(:name => "David Tennant", position: 1)
    @actors[:rose] = Actor.create!(:name => "Billie Piper", position: 2)
    Actor.class_eval do
      include RankedModel
      ranks :legacy, :column => :position
      alias_method :position, :legacy_position
      alias_method :position=, :legacy_position=
    end
  }

  describe "aliasing a legacy acts_as_list position column" do
    it "updates the position" do
      @actors[:rose].update_attributes! :position => 1
      @actors[:rose].reload
      @actors[:rose].position.should == 1
    end
  end

end
