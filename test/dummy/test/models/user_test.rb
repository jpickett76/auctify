# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "can sell things (as seller)" do
    seller = users(:eve)
    thing = seller.things.first
    assert thing.present?

    sale = seller.offer_to_sale!(thing, in: :auction, price: 1000, ends_at: 1.day.from_now)

    assert seller.sales.reload.include?(sale)
    assert thing.sales.reload.include?(sale)

    assert_equal thing, sale.item
    assert_equal seller, sale.seller
    assert_equal 1_000, sale.offered_price
    assert sale.is_a?(Auctify::Sale::Auction)
  end
end
