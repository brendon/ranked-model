require "spec_helper"

describe "notifications" do
  before do
    @notifications_count = 0
    @notification_payloads = []

    ActiveSupport::Notifications.subscribe("ranked_model.ranks_updated") do |name, start, finish, id, payload|
      @notifications_count += 1
      @notification_payloads << payload
    end
  end

  after do
    ActiveSupport::Notifications.unsubscribe("ranked_model.ranks_updated")
  end

  context "when rearranging" do
    it "notifies subscribers with the instance" do
      Number.create(order: RankedModel::MAX_RANK_VALUE)
      second_number = Number.create(order: RankedModel::MAX_RANK_VALUE)

      expect(@notifications_count).to eq(1)
      expect(@notification_payloads.last[:instance]).to eq(second_number)
    end

    context "with scope" do
      it "notifies subscribers with the instance and scope" do
        Duck.create(size: RankedModel::MAX_RANK_VALUE, pond: "Shin")
        second_duck = Duck.create(size: RankedModel::MAX_RANK_VALUE, pond: "Shin")

        expect(@notifications_count).to eq(1)
        expect(@notification_payloads.last[:instance]).to eq(second_duck)
        expect(@notification_payloads.last[:scope]).to eq(:in_shin_pond)
      end
    end

    context "with with_same" do
      it "notifies subscribers with the instance and with_same" do
        Duck.create(age: RankedModel::MAX_RANK_VALUE, pond: "Shin")
        second_duck = Duck.create(age: RankedModel::MAX_RANK_VALUE, pond: "Shin")

        expect(@notifications_count).to eq(1)
        expect(@notification_payloads.last[:instance]).to eq(second_duck)
        expect(@notification_payloads.last[:with_same]).to eq(:pond)
      end
    end
  end

  context "when rebalancing" do
    it "notifies subscribers with the instance" do
      31.times { Number.create }
      thirty_second_number = Number.create

      expect(@notifications_count).to eq(1)
      expect(@notification_payloads.last[:instance]).to eq(thirty_second_number)
    end

    context "with scope" do
      it "notifies subscribers with the instance and scope" do
        31.times { Duck.create(pond: "Shin") }
        thirty_second_duck = Duck.create(pond: "Shin")

        expect(@notifications_count).to eq(4) # Duck has four ranks
        expect(@notification_payloads.last[:instance]).to eq(thirty_second_duck)
        expect(@notification_payloads.map { |p| p[:scope] }).to include(:in_shin_pond)
      end
    end

    context "with with_same" do
      it "notifies subscribers with the instance and with_same" do
        31.times { Duck.create(pond: "Shin") }
        thirty_second_duck = Duck.create(pond: "Shin")

        expect(@notifications_count).to eq(4)
        expect(@notification_payloads.last[:instance]).to eq(thirty_second_duck)
        expect(@notification_payloads.map { |p| p[:with_same] }).to include(:pond)
      end
    end
  end

  context "when not rearranging or rebalancing" do
    it "does not notify subscribers" do
      Number.create

      expect(@notifications_count).to eq(0)
    end
  end
end
