class Item < ApplicationRecord
  STATUSES = %w[ owned wishlist considering ].freeze

  belongs_to :inbound_email, optional: true
  has_many :kit_items, dependent: :destroy
  has_many :trip_items, dependent: :destroy

  validates :name, :category, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :weight_grams, :measured_weight_grams,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :unit_weight_grams, numericality: { greater_than: 0 }, allow_nil: true

  scope :ordered, -> { order(:category, :name) }
  scope :active, -> { where(retired: false) }
  scope :owned, -> { where(status: "owned") }

  def self.categories = distinct.order(:category).pluck(:category)

  # A weight from a kitchen scale beats the one on the spec sheet.
  def effective_weight_grams = measured_weight_grams || weight_grams

  def measured? = measured_weight_grams.present?

  def per_unit? = unit_weight_grams.present?

  def unweighed? = effective_weight_grams.nil? && !per_unit?

  def weight_for(quantity)
    per_unit? ? unit_weight_grams * quantity : (effective_weight_grams || 0) * quantity
  end

  def display_name = [ manufacturer, name ].compact_blank.join(" ")
end
