# 20260926 — Trips copy a kit's lines rather than referencing the kit

## Context

A kit is a reusable packing list — "summer overnight", "shoulder season". Planning a trip
usually means starting from one and then adjusting: an extra layer for a cold forecast, the
bear canister for a park that requires it, a different weight because the fuel canister is
half full.

If a trip's gear were the kit's gear plus a set of differences, editing the kit would silently
change every past trip packed from it, and a trip's list would be something to compute rather
than something to read.

## Decision

`Trip#pack_from!(kit)` copies each kit line into a `TripItem` — quantity, worn and notes —
and records the kit on the trip for reference. After that the trip's lines are its own.

Packing from a kit skips any item already on the trip, leaving that line's edits alone. So
packing from a second kit tops a trip up rather than overwriting it.

`Trip#kit` is informational. Deleting a kit nullifies it on trips and leaves their gear in
place.

## Consequences

- A past trip's list stays exactly as it was packed, which is what makes it useful to look
  back at.
- Improving a kit does not update trips already packed from it. Re-packing picks up only
  items the trip does not already have.
- Per-trip weight overrides (`TripItem#weight_grams_override`) have somewhere to live that
  cannot leak back into the kit or the inventory.

## Alternatives considered

- **Trips reference a kit plus additions and removals.** Rejected: past trips change under
  you, and every read has to reconstruct the list.
- **Replace a trip's lines when packing from a kit.** Rejected: a second pack would throw away
  the edits that are the reason a trip diverges from its kit.
