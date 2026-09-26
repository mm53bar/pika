class Trip < ApplicationRecord
  belongs_to :kit, optional: true
  has_many :trip_items, -> { includes(:item).merge(Item.ordered).references(:item) }, dependent: :destroy
  has_many :items, through: :trip_items
  has_many :trip_meals, -> { includes(:meal).order("meals.meal_type", "meals.name").references(:meal) }, dependent: :destroy
  has_many :meals, through: :trip_meals

  validates :name, presence: true
  validate :ends_after_start

  scope :ordered, -> { order(starts_on: :desc, name: :asc) }

  REPORT_FIELDS = %i[ report worked_well didnt_work ].freeze

  def nights
    (ends_on - starts_on).to_i if starts_on && ends_on
  end

  def weight = PackWeight.new(trip_items)

  # Over once its last day has gone by. A trip with no dates is never past.
  def past?
    last_day = ends_on || starts_on
    last_day.present? && last_day < Date.current
  end

  def reported? = reported_on.present?

  def awaiting_report? = past? && !reported?

  # Saves the report and each packed line's rating and note, in one go. `lines`
  # maps trip item id to its attributes; ids that aren't this trip's are ignored.
  # The first save dates the report; later edits keep that date.
  def file_report!(report_attributes, lines = {})
    transaction do
      update!(report_attributes.slice(*REPORT_FIELDS).merge(reported_on: reported_on || Date.current))
      lines.each do |id, attributes|
        trip_items.find_by(id: id)&.update!(rating: attributes["rating"].presence, review: attributes["review"].presence)
      end
    end
  end

  def meal_calories = trip_meals.sum { |tm| (tm.meal.calories || 0) * tm.quantity }

  def meal_weight_grams = trip_meals.sum { |tm| (tm.meal.weight_grams || 0) * tm.quantity }

  # Copies the kit's lines in. Anything already packed is left as it is, so
  # packing from a second kit tops a trip up instead of clobbering its edits.
  # Returns how many lines were added.
  def pack_from!(kit)
    transaction do
      packed = trip_items.pluck(:item_id).to_set
      added = kit.kit_items.reject { |line| packed.include?(line.item_id) }
      added.each do |line|
        trip_items.create!(item: line.item, quantity: line.quantity, worn: line.worn, notes: line.notes)
      end
      update!(kit: kit)
      added.size
    end
  end

  private

  def ends_after_start
    errors.add(:ends_on, "must be on or after the start date") if nights&.negative?
  end
end
