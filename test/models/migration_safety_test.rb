require "test_helper"

# SQLite can't alter most of a table in place, so Rails rebuilds it: create a
# copy, move the rows, drop the original. Rails switches foreign keys off for
# that, but SQLite ignores the switch inside a transaction — and migrations run
# in one. Dropping the original then fires every ON DELETE CASCADE pointing at
# it. Adding one foreign key to items this way deleted every trip line.
#
# A migration that rebuilds an existing table must opt out of the transaction
# with disable_ddl_transaction!, so the switch takes effect. See
# docs/adr/20260926-sqlite-table-rebuilds-run-outside-a-transaction.md.
class MigrationSafetyTest < ActiveSupport::TestCase
  REBUILDS = /
    \b(add_foreign_key|remove_foreign_key|change_column|change_column_null|change_column_default|
       remove_column|remove_columns|rename_column|remove_reference|remove_belongs_to)\b
    | \b(add_reference|add_belongs_to)\b[^\n]*foreign_key:(?!\s*false)
  /x

  # Already run everywhere, before this rule existed.
  GRANDFATHERED = %w[ 20260926200958_add_purchase_to_items.rb ].freeze

  test "migrations that rebuild an existing table run outside a transaction" do
    offenders = Dir[Rails.root.join("db/migrate/*.rb")].filter_map do |path|
      name = File.basename(path)
      source = File.read(path)
      next if GRANDFATHERED.include?(name) || !source.match?(REBUILDS)

      name unless source.include?("disable_ddl_transaction!")
    end

    assert_empty offenders, "add disable_ddl_transaction! to: #{offenders.join(", ")}"
  end

  test "the check recognises a rebuild" do
    assert_match REBUILDS, "add_reference :items, :owner, foreign_key: { on_delete: :nullify }"
    assert_match REBUILDS, "change_column_null :items, :name, false"
    assert_no_match REBUILDS, "add_reference :items, :owner, foreign_key: false"
    assert_no_match REBUILDS, "add_column :items, :colour, :string"
  end
end
