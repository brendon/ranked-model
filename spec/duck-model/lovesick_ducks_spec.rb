require 'spec_helper'

describe LovesickDuck do
  before {
    @ducks = {
      :quacky => LovesickDuck.create(:name => 'Quacky'),
      :feathers => LovesickDuck.create(:name => 'Feathers'),
      :wingy => LovesickDuck.create(:name => 'Wingy'),
      :webby => LovesickDuck.create(:name => 'Webby'),
      :waddly => LovesickDuck.create(:name => 'Waddly'),
      :beaky => LovesickDuck.create(:name => 'Beaky')
    }
    @ducks.each { |name, duck|
      duck.reload
      duck.update :row_position => 0
      duck.save!
    }
    @ducks.each {|name, duck| duck.reload }
  }

  describe "when placing duck first" do

    context "in large numbers" do
      let!(:lovesick_ducks) { 200.times.map { LovesickDuck.create(name: "LovesickDuck #{_1 + 1}", row: :first) } }

      it "evenly spaces them" do
        expect(lovesick_ducks.pluck(:row).each_cons(2).map { _2 - _1 }).to all(eq 1000)
      end

      it "didn't rebalance them" do
        expect { lovesick_ducks.each(&:reload) }
          .not_to change { lovesick_ducks.pluck(:row) }
      end
    end

    describe "when enough room" do
      before {
        [:quacky, :feathers, :wingy, :webby, :waddly, :beaky].each_with_index do |name, i|
          LovesickDuck.where(id: @ducks[name].id).update_all(row: i * 1000)
          @ducks[name].reload
        end
      }

      it "first duck keeps the right distance" do
        expect {
          LovesickDuck.find_by(id: @ducks[:webby]).update!(row_position: :first)
        }.to change{ @ducks[:webby].reload.row }

        expect((@ducks[:webby].row - @ducks[:quacky].reload.row).abs).to be(1000)
      end
    end

    describe "when not enough spread room" do

      let(:available_room) { 1500 }

      before {
        [:quacky, :feathers, :wingy, :webby, :waddly, :beaky].each_with_index do |name, i|
          LovesickDuck.where(id: @ducks[name].id).update_all(row: RankedModel::MIN_RANK_VALUE + (i * 1000) + available_room)
          @ducks[name].reload
        end
      }

      it "first duck getting closer" do
        LovesickDuck.find_by(id: @ducks[:webby]).update!(row_position: :first)

        @ducks[:webby].reload
        @ducks[:quacky].reload

        expect((@ducks[:webby].row - @ducks[:quacky].row).abs).to eq(available_room * 0.3)
      end
    end

    describe "when rebalancing occurs" do
      before {
        [:quacky, :feathers, :wingy, :webby, :waddly, :beaky].each_with_index do |name, i|
          LovesickDuck.where(id: @ducks[name].id).update_all(row: RankedModel::MIN_RANK_VALUE + i)
          @ducks[name].reload
        end
      }

      it "all ducks spreads at a comfortable distance" do
        LovesickDuck.find_by(id: @ducks[:beaky]).update!(row_position: :first)
        [:quacky, :feathers, :wingy, :webby, :waddly, :beaky].each do |name|
          @ducks[name].reload
        end

        expect((@ducks[:beaky].row - @ducks[:quacky].row).abs).to eq(1000)
        expect((@ducks[:feathers].row - @ducks[:wingy].row).abs).to eq(1000)
        expect((@ducks[:webby].row - @ducks[:waddly].row).abs).to eq(1000)
      end
    end
  end

  describe "when placing duck last" do

    context "in large numbers" do
      let!(:lovesick_ducks) { 200.times.map { LovesickDuck.create(name: "LovesickDuck #{_1 + 1}", row: :last) } }

      it "evenly spaces them" do
        expect(lovesick_ducks.pluck(:row).each_cons(2).map { _2 - _1 }).to all(eq 1000)
      end

      it "didn't rebalance them" do
        expect { lovesick_ducks.each(&:reload) }
          .not_to change { lovesick_ducks.pluck(:row) }
      end
    end

    describe "when enough room" do
      before {
        [:quacky, :feathers, :wingy, :webby, :waddly, :beaky].each_with_index do |name, i|
          LovesickDuck.where(id: @ducks[name].id).update_all(row: i * 1000)
          @ducks[name].reload
        end
      }

      it "last duck keeps the right distance" do
        expect {
          LovesickDuck.find_by(id: @ducks[:webby]).update!(row_position: :last)
        }.to change{ @ducks[:webby].reload.row }

        expect(@ducks[:webby].row - @ducks[:beaky].reload.row).to be(1000)
      end
    end

    describe "when not enough spread room" do

      let(:available_room) { 1500 }

      before {
        [:quacky, :feathers, :wingy, :webby, :waddly, :beaky].each_with_index do |name, i|
          LovesickDuck.where(id: @ducks[name].id).update_all(row: RankedModel::MAX_RANK_VALUE - (i * 1000) - available_room)
          @ducks[name].reload
        end
      }

      it "first duck getting closer" do
        LovesickDuck.find_by(id: @ducks[:webby]).update!(row_position: :last)

        @ducks[:webby].reload
        @ducks[:quacky].reload

        expect((@ducks[:webby].row - @ducks[:quacky].row).abs).to eq(available_room * 0.3)
      end
    end

    describe "when rebalancing occurs" do
      before {
        [:quacky, :feathers, :wingy, :webby, :waddly, :beaky].each_with_index do |name, i|
          LovesickDuck.where(id: @ducks[name].id).update_all(row: RankedModel::MAX_RANK_VALUE - i)
          @ducks[name].reload
        end
      }

      it "all ducks spreads at a comfortable distance" do
        LovesickDuck.find_by(id: @ducks[:beaky]).update!(row_position: :last)
        [:quacky, :feathers, :wingy, :webby, :waddly, :beaky].each do |name|
          @ducks[name].reload
        end

        expect((@ducks[:beaky].row - @ducks[:quacky].row).abs).to eq(1000)
        expect((@ducks[:feathers].row - @ducks[:wingy].row).abs).to eq(1000)
        expect((@ducks[:webby].row - @ducks[:waddly].row).abs).to eq(1000)
      end
    end
  end
end
