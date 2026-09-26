class KitItem < ApplicationRecord
  belongs_to :kit
  include PackedLine

  validates :item_id, uniqueness: { scope: :kit_id }
end
