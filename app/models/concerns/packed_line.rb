# Shared by KitItem and TripItem: one inventory Item packed some number of times.
module PackedLine
  extend ActiveSupport::Concern

  included do
    belongs_to :item

    validates :quantity, numericality: { only_integer: true, greater_than: 0 }

    delegate :category, :consumable?, :display_name, to: :item
  end

  def line_weight_grams = item.weight_for(quantity)
end
