# frozen_string_literal: true

module Auctify
  class SalesPack < ApplicationRecord
    include Folio::FriendlyId
    include Folio::HasAttachments
    include Folio::Positionable
    include Folio::Publishable::Basic
    include Folio::Sitemap::Base

    has_many :sales, class_name: "Auctify::Sale::Base", foreign_key: :pack_id, inverse_of: :pack, dependent: :restrict_with_error
    has_many :items, through: :sales

    validates :title,
              presence: true,
              uniqueness: true

    validates :start_date,
              :end_date,
              presence: true

    validates :sales_interval,
              numericality: { greater_than: 0, less_than: 240 }

    validates :sales_beginning_hour,
              numericality: { greater_than_or_equal: 0, less_than: 24 }

    validates :sales_beginning_minutes,
              numericality: { greater_than_or_equal: 0, less_than: 60 }

    validate :validate_start_and_end_dates

    scope :ordered, -> { order(start_date: :desc, id: :desc) }

    pg_search_scope :by_query,
                    against: %i[title],
                    ignoring: :accents,
                    using: { tsearch: { prefix: true } }

    after_initialize :set_commission

    def to_label
      title
    end

    def dates_to_label
      if start_date && end_date
        if start_date.year == end_date.year
          if start_date.month == end_date.month
            "#{start_date.strftime('%-d.')}–#{end_date.strftime('%-d. %-m. %y')}"
          else
            "#{start_date.strftime('%-d. %-m.')} – #{end_date.strftime('%-d. %-m. %y')}"
          end
        else
          "#{start_date.strftime('%-d. %-m. %y')} – #{end_date.strftime('%-d. %-m. %y')}"
        end
      end
    end

    private
      def validate_start_and_end_dates
        if start_date.present? && end_date.present? && start_date > end_date
          errors.add(:end_date, :smaller_than_start_date)
        end
      end

      def set_commission
        return if self.commission_in_percent.present?

        self.commission_in_percent = Auctify.configuration.auctioneer_commission_in_percent
      end
  end
end

# == Schema Information
#
# Table name: auctify_sales_packs
#
#  id                      :bigint(8)        not null, primary key
#  title                   :string
#  description             :text
#  position                :integer          default(0)
#  slug                    :string
#  place                   :string
#  published               :boolean          default(FALSE)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  sales_count             :integer          default(0)
#  start_date              :date
#  end_date                :date
#  sales_interval          :integer          default(3)
#  sales_beginning_hour    :integer          default(20)
#  sales_beginning_minutes :integer          default(0)
#  commission_in_percent   :integer
#
# Indexes
#
#  index_auctify_sales_packs_on_position   (position)
#  index_auctify_sales_packs_on_published  (published)
#  index_auctify_sales_packs_on_slug       (slug) UNIQUE
#
