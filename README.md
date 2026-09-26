# Pika

A small self-hosted app for backpacking gear.

- **Gear** — your inventory, by category, with listed and weighed weights. Owned, wishlist,
  considering, retired.
- **Kits** — reusable packing lists ("summer overnight").
- **Trips** — pack from a kit, then adjust. Base, worn and consumable weights, per-category
  totals, and per-trip weight overrides.
- **Meals** — calories, weight, calorie density, ratings; add them to trips.
- **Reference lists** — other people's published gear lists, to compare against.

Every page is also a JSON API at the same URL (`/trips/1.json`), which is how data gets
loaded. It's documented in [`docs/api.md`](docs/api.md), which a running Pika also serves at
`/llms.txt`, `/docs/api` and via an RFC 9727 catalog at `/.well-known/api-catalog`. To hand
Pika to an LLM agent, point it at `/llms.txt`.

## Running it

```sh
bin/setup
bin/dev
```

`bin/ci` runs the full gate: rubocop, bundler-audit, importmap audit, brakeman, tests, seeds
and a production boot check.

## Deploying

`compose.yaml` is a template for a single container (web and background jobs together, SQLite
on a mounted volume). Set `SECRET_KEY_BASE`, the volume path and the `user:` UID:GID.

There is **no authentication**. Run it only somewhere that isn't publicly reachable — see
`docs/adr/20260926-no-auth-needed.md`.

## Credits

The searchable select (`app/javascript/controllers/select_controller.js`,
`app/views/shared/components/select/`, `app/assets/tailwind/select.css`) is from
[Rails Blocks](https://railsblocks.com), built on [Tom Select](https://tom-select.js.org)
(Apache 2.0) and [Floating UI](https://floating-ui.com) (MIT).

