class TripMeal < ApplicationRecord
  belongs_to :trip
  belongs_to :meal

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
end
