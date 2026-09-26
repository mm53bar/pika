# 20260926 — Consumable is a flag on the item, not a property of its category

## Context

Backpackers compare three weights: **base** (carried and not used up), **worn**, and
**consumables** (food, water, fuel — gone by the end). Base weight is the number that matters
when choosing gear, so anything misfiled as consumable makes a pack look lighter than it is.

A simple rule is to decide consumability from the category: anything filed under Food, Water
or Fuel is a consumable. Ordinary kit breaks that immediately. Water bottles live in Water and
come home. So does a bear canister, which is naturally filed with Food. Category describes what
a thing is *for*; consumability describes whether it comes home. They are different questions,
and conflating them hides durable gear from base weight.

## Decision

`Item#consumable` is a boolean, set per item, defaulting to false. Category is free text and
has no effect on weight classification. `PackWeight` classifies each line as worn (checked
first), else consumable, else base.

Reference items carry the same flag, so a published list can be compared like-for-like.

## Consequences

- A bottle or bear canister counts toward base weight regardless of where it is filed.
- Every consumable has to be marked. Forgetting inflates base weight, which errs in the safe
  direction — a pack that seems heavier than it is, not lighter.
- A migration from a category-based system has to decide each item, not map categories. That
  decision belongs to the migration, not to this app.

## Alternatives considered

- **Keep a list of consumable categories.** Rejected: it is the rule that produced the wrong
  numbers, and every exception would need a new category.
- **Consumable categories plus a per-item override.** Rejected: two sources of truth for one
  yes/no question, and the override would be needed for exactly the common cases.
