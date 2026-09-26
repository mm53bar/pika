# Someone else's published gear list, kept to compare against. Its items are
# plain rows, not inventory: nothing here is owned.
class ReferenceList < ApplicationRecord
  has_many :reference_items, -> { order(:category, :name) }, dependent: :destroy

  validates :name, presence: true
  validates :source_url, format: { with: %r{\Ahttps?://\S+\z}i }, allow_blank: true

  scope :ordered, -> { order(:name) }

  def weight = PackWeight.new(reference_items)

  # Re-checked at render time for rows written around the validation.
  def safe_source_url
    uri = URI.parse(source_url.to_s)
    uri.to_s if uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    nil
  end
end
