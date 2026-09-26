class TripItem < ApplicationRecord
  belongs_to :trip
  include PackedLine

  validates :item_id, uniqueness: { scope: :trip_id }
  validates :weight_grams_override, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  def line_weight_grams = weight_grams_override || super
end
