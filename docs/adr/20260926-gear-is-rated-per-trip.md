# 20260926 — Gear is rated per trip, not once per item

## Context

After a trip the useful questions are how it went and how the gear did. The obvious model is
a star rating on each item. But gear performs relative to conditions: a quilt that is right
for a summer ridge is miserable on a frosty September one, and a rain shell only earns its
place on the trips it rains. A single rating per item would be overwritten by whichever trip
came last, and the reason behind it would be lost.

## Decision

A rating (1–5) and a short note live on the **trip line** (`TripItem#rating`, `#review`) —
how this item did on this trip. The trip itself carries a free-text report in three parts:
how it went, what worked well, what didn't.

An item's page shows its history across trips, most recent first, and an average. The
average is a summary for scanning, not a stored value.

A past trip (its last day has gone by) opens on the report. Its packing list stays editable,
folded away beneath it, because history sometimes needs correcting. The trips list flags past
trips with no report.

## Consequences

- An item's ratings carry their context: the trip, its season and terrain, and a note.
- Rating an item means packing it on a trip first. There is no rating for gear never used.
- Meals keep their own single rating, since how a meal tastes doesn't depend much on the trip.

## Alternatives considered

- **A rating on the item.** Rejected: one number for all conditions, overwritten each time.
- **A separate trip report record.** Rejected: one report per trip, with nothing of its own
  beyond these fields, is the trip.
