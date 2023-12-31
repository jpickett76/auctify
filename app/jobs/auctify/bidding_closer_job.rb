# frozen_string_literal: true

module Auctify
  class BiddingCloserJob < Auctify::ApplicationJob
    queue_as :default

    def perform(auction_id:)
      return if auction_id.blank?
      begin
        auction = Auctify::Sale::Auction.find(auction_id)
      rescue ActiveRecord::RecordNotFound
        return
      end

      if auction.currently_ends_at <= Time.current
        auction.close_bidding! if auction.in_sale?
      else
        self.class.set(wait_until: auction.currently_ends_at)
                  .perform_later(auction_id: auction.id)
      end
    end
  end
end
