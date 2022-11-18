require "spec_helper"

describe Duck do
  before do
    5.times do |i|
      Duck.create(name: "Duck #{i + 1}")
    end
  end

  describe "updating a duck order with last" do
    it "should maintain the order after creating a new duck" do
      duck = Duck.first
      duck.update(row_position: :last)
      expect(duck.row_rank).to eq(4)

      Duck.create(name: "Wacky")

      expect(duck.row_rank).to eq(4)

      duck.update(pond: 'Shin')
      expect(duck.row_rank).to eq(4)
    end
  end

  describe "updating a duck order with first" do
    it "should maintain the order after creating a new duck" do
      duck = Duck.last
      duck.update(row: :first)
      expect(duck.row_rank).to eq(0)

      Duck.create(name: "Wacky")

      expect(duck.row_rank).to eq(0)

      duck.update(pond: 'Shin')
      expect(duck.row_rank).to eq(0)
    end
  end

  describe "updating a duck order with up" do
    it "should maintain the order after creating a new duck" do
      duck = Duck.rank(:row)[2]
      duck.update(row: :up)
      expect(duck.row_rank).to eq(3)

      Duck.create(name: "Wacky")

      expect(duck.row_rank).to eq(3)

      duck.update(pond: 'Shin')
      expect(duck.row_rank).to eq(3)
    end
  end

  describe "updating a duck order with down" do
    it "should maintain the order after creating a new duck" do
      duck = Duck.rank(:row)[2]
      duck.update(row: :down)
      expect(duck.row_rank).to eq(1)

      Duck.create(name: "Wacky")

      expect(duck.row_rank).to eq(1)

      duck.update(pond: 'Shin')
      expect(duck.row_rank).to eq(1)
    end
  end
end
