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
- **Grams reach JSON as numbers.** Use `PackWeight.json_grams` for any weight in a view;
  Rails would serialise a decimal as a string.
- Prefer Rails conventions over architecture-heavy patterns. No `app/services/`. Extract
  nouns, not verbs. Reach for a plain model method before a new abstraction.
- Testing: Minitest with fixtures, Rack integration tests via `ActionDispatch::IntegrationTest`
  + `assert_select`. No RSpec, no factories, no mocking library, no Capybara — see
  `docs/adr/20260926-integration-tests-over-system-tests.md`.
- **Test-environment defaults can hide production failures.** `bin/ci` runs
  `script/production-boot-check` for this reason. When a test asserts the *absence* of a
  protection, switch that protection on inside the test and assert both halves — see the CSRF
  test in `test/integration/api_test.rb`.
- Run `bin/ci` before considering work complete — the full gate, not just `bin/rails test`.
  If it fails, fix or surface it; do not declare work done.
- Secrets are a plain `SECRET_KEY_BASE` env var. Rails encrypted credentials are unused and
  git-ignored. `compose.yaml` carries a placeholder. See `docs/adr/20260926-secrets-from-env.md`.
- Deployment is a single container: web and Solid Queue run together in Puma — no separate
  worker service, no Redis.
- Record significant architectural decisions in `docs/adr/` (`## Context` / `## Decision` /
  `## Consequences` / `## Alternatives considered`). Read that directory before assuming a
  design decision hasn't been made. Coding preferences go here instead.
