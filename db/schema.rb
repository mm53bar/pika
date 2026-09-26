# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_26_185609) do
  create_table "items", force: :cascade do |t|
    t.string "name", null: false
    t.string "manufacturer"
    t.string "category", default: "Misc", null: false
    t.integer "weight_grams"
    t.integer "measured_weight_grams"
    t.decimal "unit_weight_grams", precision: 8, scale: 2
    t.string "unit_label"
    t.string "status", default: "owned", null: false
    t.boolean "worn", default: false, null: false
    t.boolean "consumable", default: false, null: false
    t.boolean "retired", default: false, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_items_on_category"
  end

  create_table "kit_items", force: :cascade do |t|
    t.integer "kit_id", null: false
    t.integer "item_id", null: false
    t.integer "quantity", default: 1, null: false
    t.boolean "worn", default: false, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_kit_items_on_item_id"
    t.index ["kit_id", "item_id"], name: "index_kit_items_on_kit_id_and_item_id", unique: true
    t.index ["kit_id"], name: "index_kit_items_on_kit_id"
  end

  create_table "kits", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "season"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "meals", force: :cascade do |t|
    t.string "name", null: false
    t.string "brand"
    t.string "meal_type", default: "dinner", null: false
    t.integer "calories"
    t.integer "weight_grams"
    t.integer "rating"
    t.boolean "would_buy_again"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "reference_items", force: :cascade do |t|
    t.integer "reference_list_id", null: false
    t.string "name", null: false
    t.string "manufacturer"
    t.string "category", default: "Misc", null: false
    t.integer "weight_grams"
    t.integer "quantity", default: 1, null: false
    t.boolean "worn", default: false, null: false
    t.boolean "consumable", default: false, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reference_list_id"], name: "index_reference_items_on_reference_list_id"
  end

  create_table "reference_lists", force: :cascade do |t|
    t.string "name", null: false
    t.string "author"
    t.string "source_url"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "trip_items", force: :cascade do |t|
    t.integer "trip_id", null: false
    t.integer "item_id", null: false
    t.integer "quantity", default: 1, null: false
    t.boolean "worn", default: false, null: false
    t.integer "weight_grams_override"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_trip_items_on_item_id"
    t.index ["trip_id", "item_id"], name: "index_trip_items_on_trip_id_and_item_id", unique: true
    t.index ["trip_id"], name: "index_trip_items_on_trip_id"
  end

  create_table "trip_meals", force: :cascade do |t|
    t.integer "trip_id", null: false
    t.integer "meal_id", null: false
    t.integer "quantity", default: 1, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["meal_id"], name: "index_trip_meals_on_meal_id"
    t.index ["trip_id"], name: "index_trip_meals_on_trip_id"
  end

  create_table "trips", force: :cascade do |t|
    t.string "name", null: false
    t.string "destination"
    t.string "trail"
    t.date "starts_on"
    t.date "ends_on"
    t.string "season"
    t.string "terrain"
    t.integer "kit_id"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kit_id"], name: "index_trips_on_kit_id"
  end

  add_foreign_key "kit_items", "items", on_delete: :cascade
  add_foreign_key "kit_items", "kits", on_delete: :cascade
  add_foreign_key "reference_items", "reference_lists", on_delete: :cascade
  add_foreign_key "trip_items", "items", on_delete: :cascade
  add_foreign_key "trip_items", "trips", on_delete: :cascade
  add_foreign_key "trip_meals", "meals", on_delete: :cascade
  add_foreign_key "trip_meals", "trips", on_delete: :cascade
  add_foreign_key "trips", "kits", on_delete: :nullify
end
