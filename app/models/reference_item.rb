class ReferenceItem < ApplicationRecord
  belongs_to :reference_list

  validates :name, :category, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :weight_grams, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  def line_weight_grams = (weight_grams || 0) * quantity

  def display_name = [ manufacturer, name ].compact_blank.join(" ")
end
