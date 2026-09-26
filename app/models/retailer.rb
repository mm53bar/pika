# A store's sender address or domain that marks a message as a gear purchase.
# Matched anywhere in the message — header or body — because order emails are
# usually forwarded, so the store's address lives in the body, not the From
# header.
#
# It ships empty: which stores someone buys from is personal data, and this
# repo is public. Load a deployment's list over the API. An empty list still
# works; the classifier's order-language signals carry it alone.
class Retailer < ApplicationRecord
  validates :value, presence: true, uniqueness: { case_sensitive: false }

  before_validation { self.value = value.to_s.strip.downcase.presence }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:value) }

  def self.match_values = active.pluck(:value)
end
