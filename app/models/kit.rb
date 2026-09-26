# A reusable packing list — "summer overnight", "shoulder season" — that a trip
# starts from and then diverges. Trips copy its lines rather than link to them.
class Kit < ApplicationRecord
  has_many :kit_items, -> { includes(:item).merge(Item.ordered).references(:item) }, dependent: :destroy
  has_many :items, through: :kit_items
  has_many :trips, dependent: :nullify

  validates :name, presence: true

  scope :ordered, -> { order(:name) }

  def weight = PackWeight.new(kit_items)
end
