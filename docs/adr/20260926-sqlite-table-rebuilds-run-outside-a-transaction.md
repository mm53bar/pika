# 20260926 — SQLite table rebuilds run outside a transaction

## Context

SQLite can't alter most of a table in place — adding or removing a foreign key, changing a
column's type, nullability or default. Rails does it by rebuilding the table: create a copy
with the new definition, copy the rows, drop the original, rename the copy. It turns foreign
keys off first so the drop doesn't cascade.

SQLite ignores `PRAGMA foreign_keys = OFF` inside a transaction, and Rails runs each migration
in one. So the drop runs with foreign keys on, and every `ON DELETE CASCADE` pointing at the
table fires. The rows being rebuilt survive, because they were copied first; the rows in
*other* tables that referenced them are deleted.

This happened: adding a nullable foreign key from `items` to `inbound_emails` rebuilt `items`,
and every `trip_items` row went with it. Nothing reported it. The suite stayed green, because
tests load the schema rather than running migrations over data.

## Decision

A migration that rebuilds an existing table declares `disable_ddl_transaction!`, so foreign
keys really are off while the table is swapped. `test/models/migration_safety_test.rb` fails
the gate for any new migration that makes a rebuilding change without it. Creating a new
table with foreign keys is not a rebuild and needs nothing.

## Consequences

- Such a migration is not atomic: if it fails halfway, the database can be left between
  states. Keep rebuilding migrations to one change each, and back up the database before
  deploying one.
- The check is a pattern match over migration source. It catches the ordinary calls; a
  rebuild reached some other way (raw SQL, `change_table` with a foreign key) is not seen, and
  needs the same care by hand.
- `20260926200958_add_purchase_to_items.rb` predates this and is exempt. It has already run
  everywhere; the rows it deleted were restored from their source.

## Alternatives considered

- **Drop the `ON DELETE CASCADE` foreign keys.** Rejected: they are what keeps a deleted item
  from leaving dangling trip and kit lines.
- **Avoid foreign keys on columns added later.** Rejected: it trades a loud rule for silently
  unenforced references.
