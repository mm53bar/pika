class Meal < ApplicationRecord
  MEAL_TYPES = %w[ breakfast lunch dinner snack ].freeze

  has_many :trip_meals, dependent: :destroy

  validates :name, presence: true
  validates :meal_type, inclusion: { in: MEAL_TYPES }
  validates :rating, inclusion: { in: 1..5 }, allow_nil: true
  validates :calories, :weight_grams, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  scope :ordered, -> { order(:meal_type, :brand, :name) }

  def display_name = [ brand, name ].compact_blank.join(" ")

  def calories_per_100g
    (calories * 100.0 / weight_grams).round if calories && weight_grams&.positive?
  end
end
