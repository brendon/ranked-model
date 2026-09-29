require 'spec_helper'

describe Number, :if => ActiveRecord.respond_to?(:permanent_connection_checkout) do

  around { |example|
    begin
      checkout_was = ActiveRecord.permanent_connection_checkout
      ActiveRecord.permanent_connection_checkout = :disallowed
      example.run
    ensure
      ActiveRecord.permanent_connection_checkout = checkout_was
    end
  }

  # A fresh thread holds no connection lease, unlike the example's own thread
  # where DatabaseCleaner has checked one out for its transaction.
  def without_leased_connection
    Thread.new {
      begin
        yield
      ensure
        Number.delete_all
      end
    }.value
  end

  it "rearranges and reads ranks without permanently checking out a connection" do
    ranks = without_leased_connection {
      first = Number.create! :order => 100
      second = Number.create! :order => 100
      [first.reload.order_rank, second.reload.order_rank]
    }

    expect(ranks).to eq([0, 1])
  end

end
