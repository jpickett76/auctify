# frozen_string_literal: true

require "test_helper"

module Auctify
  module Sale
    class AuctionConfigTest < ActiveSupport::TestCase
      attr_reader :auction, :registrations

      include Auctify::AuctionHelpers


      test "when config :autoregister_all_users_as_bidders is set => do it" do
        # default is []
        Auctify.configure do |config|
          config.autoregister_as_bidders_all_instances_of_classes = []
        end

        users_count = User.count
        assert users_count.positive?

        auction = Auctify::Sale::Auction.create!(seller: users(:eve), item: things(:apple), offered_price: 123.4)
        assert_equal 0, auction.bidder_registrations.size

        Auctify.configure do |config|
          config.autoregister_as_bidders_all_instances_of_classes = [User]
        end

        auction = Auctify::Sale::Auction.create!(seller: users(:eve), item: things(:apple), offered_price: 123.4)
        assert_equal users_count, auction.bidder_registrations.size
        assert_equal users_count, auction.bidder_registrations.approved.size, auction.bidder_registrations.to_json
      end

      test "prolongs auction time on bid within limit" do
        auction = auctify_sales(:auction_in_progress)
        lucifer = users(:lucifer)
        adam = users(:adam)
        assert_equal [lucifer, adam].sort, auction.bids.collect { |b| b.bidder }.sort
        allow_bids_for([lucifer, adam], auction)

        original_end_time = Time.current + 1.hour
        limit = 2.minutes
        auction.ends_at = original_end_time
        auction.aasm_state = :accepted # redoing start_sale
        auction.start_sale!

        assert_equal original_end_time, auction.currently_ends_at
        assert_equal limit, Auctify.configuration.auction_prolonging_limit

        assert auction.bid!(bid_for(lucifer, 1_001))

        assert_equal original_end_time, auction.currently_ends_at

        just_before_limit_time = original_end_time - limit - 1.second
        Time.stub(:current, just_before_limit_time) { assert auction.bid!(bid_for(adam, 1_002)) }

        assert_equal original_end_time, auction.currently_ends_at

        breaking_limit_time = original_end_time - limit
        Time.stub(:current, breaking_limit_time) { assert auction.bid!(bid_for(lucifer, 1_003)) }

        assert_equal original_end_time, auction.currently_ends_at

        just_after_limit_time = original_end_time - limit + 1.second
        Time.stub(:current, just_after_limit_time) { assert auction.bid!(bid_for(adam, 1_004)) }
        # comparing time with seconds precision, use `.to_i`
        assert_equal (just_after_limit_time + limit).to_i, auction.currently_ends_at.to_i

        right_before_end_time = auction.currently_ends_at - 1.second
        Time.stub(:current, right_before_end_time) { assert auction.bid!(bid_for(lucifer, 1_005)) }
        assert_equal (right_before_end_time + limit).to_i, auction.currently_ends_at.to_i

        at_end_time = auction.currently_ends_at
        Time.stub(:current, at_end_time) { assert auction.bid!(bid_for(adam, 1_006)) }
        assert_equal (at_end_time + limit).to_i, auction.currently_ends_at.to_i

        end_time = auction.currently_ends_at
        Time.stub(:current, end_time + 1.second) { assert_not auction.bid!(bid_for(lucifer, 1_007)) }
        assert_equal end_time.to_i, auction.currently_ends_at.to_i
      end

      test "respects config.auction_prolonging_limit change" do
        auction = auctify_sales(:auction_in_progress)
        lucifer = users(:lucifer)
        adam = users(:adam)
        allow_bids_for([lucifer, adam], auction)

        original_end_time = Time.current + 1.hour
        auction.ends_at = original_end_time
        auction.aasm_state = :accepted # redoing start_sale
        auction.start_sale!

        limit = 2.minutes # default
        assert_equal original_end_time, auction.currently_ends_at
        assert_equal limit, Auctify.configuration.auction_prolonging_limit

        bid_time = original_end_time - limit - 1.second
        Time.stub(:current, bid_time) { assert auction.bid!(bid_for(lucifer, 1_002)) }

        assert_equal original_end_time.to_i, auction.currently_ends_at.to_i

        # lets enlarge limit without changing bid_time
        Auctify.configure { |c| c.auction_prolonging_limit = 10.minutes }
        Time.stub(:current, bid_time) { assert auction.bid!(bid_for(adam, 1_003)) }

        assert_equal (bid_time + 10.minutes).to_i, auction.currently_ends_at.to_i
        Auctify.configure { |c| c.auction_prolonging_limit = 2.minutes }
      end
    end
  end
end