# frozen_string_literal: true

module Auctify
  module Sale
    class Base < ApplicationRecord
      self.table_name = "auctify_sales"

      belongs_to :seller, polymorphic: true
      belongs_to :buyer, polymorphic: true, optional: true
      belongs_to :item, polymorphic: true

      validate :valid_seller
      validate :valid_item
      validate :valid_buyer

      private
        def valid_seller
          db_seller = db_presence_of(seller)

          if db_seller.present?
            errors.add(:seller, :not_auctified) unless db_seller.class.included_modules.include?(Auctify::Seller)
          else
            errors.add(:seller, :required)
          end
        end

        def valid_item
          db_item = db_presence_of(item)
          if db_item.present?
            errors.add(:item, :not_auctified) unless db_item.class.included_modules.include?(Auctify::Item)
          else
            errors.add(:item, :required)
          end
        end

        def valid_buyer
          db_buyer = db_presence_of(buyer)
          if db_buyer.present?
            errors.add(:buyer, :not_auctified) unless db_buyer.class.included_modules.include?(Auctify::Buyer)
          elsif buyer.present?
            errors.add(:buyer, :required)
          end
        end

        def db_presence_of(record)
          return nil if record.blank?

          record.reload
        rescue ActiveRecord::RecordNotFound
          nil
        end
    end
  end
end

# == Schema Information
#
# Table name: auctify_sales
#
#  id          :integer          not null, primary key
#  buyer_type  :string
#  item_type   :string           not null
#  seller_type :string           not null
#  type        :string           default("Auctify::Sale::Base")
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  buyer_id    :integer
#  item_id     :integer          not null
#  seller_id   :integer          not null
#
# Indexes
#
#  index_auctify_sales_on_buyer_type_and_buyer_id    (buyer_type,buyer_id)
#  index_auctify_sales_on_item_type_and_item_id      (item_type,item_id)
#  index_auctify_sales_on_seller_type_and_seller_id  (seller_type,seller_id)
#