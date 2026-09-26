# Pika — agent guidance

A self-hosted Rails app for backpacking gear: an inventory of what you own, reusable kits,
trips packed from them with base / worn / consumable weights, a meal library, and other
people's published gear lists to compare against. This file is standing rules, not a spec —
read the code and `docs/adr/` for the actual design.

## Standing rules

- **Nothing personal goes in this repository.** It is public. The owner's gear never appears
  here — not by name, not by weight, not paraphrased as a generic example. Nor do prices,
  order numbers, trip names, dates, places, reservation numbers, contacts, hostnames or IP
  addresses — not in `db/seeds.rb`, fixtures, tests, docs or commit messages. A deployment's
  gear arrives over the JSON API after it is running. See
  `docs/adr/20260926-no-personal-data-in-this-repo.md`. This covers git history too.
- **No real gear list of any kind is in the repo** — not the owner's, and not someone else's
  published or newsletter-gated list either. Every fixture is a placeholder named
  `Example …`. Anything a test or doc needs is invented, not borrowed from a real list.
- **Weights are grams.** Integers everywhere except `Item#unit_weight_grams`, which is a
  decimal because things packed by the piece can weigh a fraction of a gram. Display
  converts; storage never does.
- **One order of precedence for a packed line's weight:** `TripItem#weight_grams_override`
  (this trip only, ignores quantity) → `Item#unit_weight_grams × quantity` → the item's
  measured weight → its listed weight, × quantity. `Item#weight_for` and
  `PackedLine#line_weight_grams` own it; nothing else re-derives it.
- **Consumable is a flag on the item, never inferred from its category.** A water bottle
  filed under Water is base weight. See `docs/adr/20260926-consumable-is-an-item-flag.md`.
  `PackWeight` checks worn first, then consumable, then base.
- **Trips copy kit lines; they don't reference them.** `Trip#pack_from!` skips anything
  already packed, so packing twice tops up rather than clobbering. See
  `docs/adr/20260926-trips-copy-kits.md`.
- A packed line's `worn` defaults to the item's `worn` when the caller doesn't say. That
  defaulting lives in the line controllers' `create`, where "not given" is distinguishable
  from `false`.
- No authentication, on the API or the UI — no `User` model, no login, no proxy-auth headers.
  It must only ever run somewhere that isn't publicly reachable. See
  `docs/adr/20260926-no-auth-needed.md`.
- The JSON API is ordinary resourceful Rails — same URLs as the HTML routes, format
  negotiated. There is no `/api` namespace. Lines are nested for create
  (`/trips/:id/trip_items`) and shallow for update/destroy (`/trip_items/:id`). A line's
  `item_id` cannot change after creation. `GET /items.json` returns the whole inventory unless
  filtered; the HTML page defaults to owned, active gear. `docs/api.md` documents the API and is served
  verbatim at `/llms.txt` and `/docs/api` — keep it in step with any change to routes,
  fields or JSON shapes. `test/integration/discovery_test.rb` checks every advertised
  discovery URL resolves.
- **Branch on `request.format.json?`, never `request.format.html?`.** curl and agents send
  `Accept: */*`, which renders HTML while `html?` is false — the page then gets the JSON
  branch's instance variables and crashes. `test/integration/pages_test.rb` covers it.
- **Grams reach JSON as numbers.** Use `PackWeight.json_grams` for any weight in a view;
  Rails would serialise a decimal as a string.
- Prefer Rails conventions over architecture-heavy patterns. No `app/services/`. Extract
  nouns, not verbs. Reach for a plain model method before a new abstraction.
- Testing: Minitest with fixtures, Rack integration tests via `ActionDispatch::IntegrationTest`
  + `assert_select`. No RSpec, no factories, no mocking library — see
  `docs/adr/20260926-integration-tests-over-system-tests.md`. The one exception: system tests
  (Capybara + Cuprite) for the searchable select, whose behaviour only exists in a browser —
  see `docs/adr/20260926-browser-tests-for-the-searchable-select.md`.
- **Categories are picked with `category_select`**, never a raw text field or `<datalist>`.
  The select itself (`select_controller.js`, `shared/components/select/`,
  `app/assets/tailwind/select.css`) is vendored from Rails Blocks and credited in the README —
  keep the credit, and prefer configuring it through the partial's locals over editing it.
- **Test-environment defaults can hide production failures.** `bin/ci` runs
  `script/production-boot-check` for this reason. When a test asserts the *absence* of a
  protection, switch that protection on inside the test and assert both halves — see the CSRF
  test in `test/integration/api_test.rb`.
- **A migration that rebuilds an existing SQLite table declares `disable_ddl_transaction!`.**
  Adding a foreign key, or changing a column's type, null or default, rebuilds the table, and
  inside a transaction the drop cascades to every child row — this deleted every trip line once.
  `test/models/migration_safety_test.rb` enforces it. See
  `docs/adr/20260926-sqlite-table-rebuilds-run-outside-a-transaction.md`.
- Run `bin/ci` before considering work complete — the full gate, not just `bin/rails test`.
  If it fails, fix or surface it; do not declare work done.
- Secrets are a plain `SECRET_KEY_BASE` env var. Rails encrypted credentials are unused and
  git-ignored. `compose.yaml` carries a placeholder. See `docs/adr/20260926-secrets-from-env.md`.
- **Purchase intake never takes mail that isn't Pika's.** The mailbox is shared with other
  apps. `PurchaseEmailClassifier` only decides what is worth an LLM call; a message is moved
  into Pika's folder only once `InboundEmail#claimable?` — the LLM confirmed a gear purchase, a
  human handled it, or the LLM never managed a read but a known retailer sent it. `not_gear`
  mail stays in INBOX, is never re-read, and never moves. Fetch with `BODY.PEEK[]`; move only
  into Pika's own folder. See `docs/adr/20260926-purchase-intake-from-a-shared-mailbox.md`.
- **Nothing from an email reaches the inventory without review.** Intake proposes;
  `InboundEmail#add_items!` is the only path from email to `Item`, called by a human (page or
  API). The LLM prompt in `GearTriager` was tuned against a live model — change it by testing
  against one, not by editing it blind. It must never be given, or produce, real personal
  examples in this repo.
- The `Retailer` list ships empty — which stores someone buys from is personal. Load it over
  the API.
- Deployment is a single container: web and Solid Queue run together in Puma — no separate
  worker service, no Redis.
- Record significant architectural decisions in `docs/adr/` (`## Context` / `## Decision` /
  `## Consequences` / `## Alternatives considered`). Read that directory before assuming a
  design decision hasn't been made. Coding preferences go here instead.
