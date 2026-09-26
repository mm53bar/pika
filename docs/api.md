# Pika JSON API

Every page in Pika is also a JSON endpoint: add `.json` to the URL (or send
`Accept: application/json`). The same URLs create, update and delete. There is no
separate `/api` namespace and no authentication — see
`docs/adr/20260926-no-auth-needed.md`.

Examples use `$PIKA` for the base URL, e.g. `http://localhost:3000`.

## Finding this document

A running Pika serves this file itself, so it always matches the version deployed:

| URL | Serves |
|---|---|
| `/llms.txt` | This document as plain text, for LLMs |
| `/docs/api.md` | This document as `text/markdown` |
| `/docs/api` | This document as a web page |
| `/.well-known/api-catalog` | An RFC 9727 API catalog linking to the above |

Every response carries a `Link` header with `rel="api-catalog"` and `rel="service-doc"`,
so a client that fetches any page can find the rest.

## Conventions

- **Request bodies** are JSON, wrapped in the resource name:
  `{"item": {"name": "Example Tent", "category": "Shelter"}}`. Send
  `Content-Type: application/json`. No CSRF token is needed for JSON.
- **Weights are grams**, as JSON numbers. Whole values are integers; fractions are kept
  exact (`2.5`). Dates are `YYYY-MM-DD`. Timestamps are ISO 8601 UTC.
- **Status codes:**

  | Code | Meaning |
  |---|---|
  | `200` | Read or update succeeded; the body is the record |
  | `201` | Created; the body is the record, top-level resources also send `Location` |
  | `204` | Deleted; no body |
  | `400` | A required parameter is missing (e.g. `kit_id` on pack) |
  | `404` | No record with that id |
  | `422` | Validation failed; the body is `{"errors": {"field": ["message", …]}}` |

- **Ids are integers.** Lines (an item on a trip or kit, a meal on a trip, an item on a
  reference list) have their own ids, separate from the item's.

## Resources

| Resource | Collection | Record |
|---|---|---|
| Items (the gear inventory) | `/items.json` | `/items/:id.json` |
| Kits (reusable packing lists) | `/kits.json` | `/kits/:id.json` |
| Trips | `/trips.json` | `/trips/:id.json` |
| Meals | `/meals.json` | `/meals/:id.json` |
| Reference lists (someone else's list, to compare) | `/reference_lists.json` | `/reference_lists/:id.json` |

Each supports `GET` (index and show), `POST` to the collection, `PATCH` and `DELETE` on
the record.

Lines are **created under their parent** and **updated or deleted by their own id**:

| Line | Create | Update / delete |
|---|---|---|
| Item on a trip | `POST /trips/:trip_id/trip_items.json` | `/trip_items/:id.json` |
| Item in a kit | `POST /kits/:kit_id/kit_items.json` | `/kit_items/:id.json` |
| Meal on a trip | `POST /trips/:trip_id/trip_meals.json` | `/trip_meals/:id.json` |
| Item on a reference list | `POST /reference_lists/:id/reference_items.json` | `/reference_items/:id.json` |

A line's `item_id` or `meal_id` is fixed once created. To swap one item for another,
delete the line and create a new one.

### Item

| Field | Type | Notes |
|---|---|---|
| `name` | string, required | |
| `manufacturer` | string | |
| `category` | string, required | Free text, default `Misc`. Groups the display only; it never decides weight classification. |
| `weight_grams` | integer ≥ 0 | Listed weight, from a spec sheet or retailer |
| `measured_weight_grams` | integer ≥ 0 | Weighed on a scale. Used instead of `weight_grams` when set. |
| `unit_weight_grams` | number > 0 | For things packed by count. When set, a line weighs this × quantity. |
| `unit_label` | string | What one unit is called, e.g. `piece` |
| `status` | `owned` \| `wishlist` \| `considering` | Default `owned` |
| `worn` | boolean | Usually worn rather than carried. The default for new lines. |
| `consumable` | boolean | Used up on a trip (food, fuel). Set per item — see below. |
| `retired` | boolean | No longer in use; kept for history |
| `notes` | string | |

Read-only in responses: `id`, `effective_weight_grams` (measured, else listed), `url`,
`created_at`, `updated_at`.

`GET /items.json` returns **every** item. Filters combine, and only those given apply:
`?status=owned|wishlist|considering`, `?retired=1` (retired only), `?retired=0` (active
only). `?status=owned&retired=0` is what you own and still use.

### Trip

| Field | Type | Notes |
|---|---|---|
| `name` | string, required | |
| `trail`, `destination`, `season`, `terrain` | string | Free text |
| `starts_on`, `ends_on` | date | `ends_on` must not be before `starts_on` |
| `notes` | string | |

Read-only: `nights` (from the dates, or `null`), `kit_id` (the last kit it was packed
from), `url`.

`GET /trips/:id.json` also returns `weight`, `trip_items`, `trip_meals`,
`meal_calories` and `meal_weight_grams`.

### Trip item (and kit item)

| Field | Type | Notes |
|---|---|---|
| `item_id` | integer, required on create | |
| `quantity` | integer > 0 | Default 1 |
| `worn` | boolean | **Omitted on create → the item's own `worn`.** |
| `weight_grams_override` | integer ≥ 0 | Trip items only. This line's total weight for this trip, ignoring quantity. |
| `notes` | string | |

Read-only: `name`, `category`, `consumable` (all from the item) and `line_weight_grams`.
An item can appear on a trip (or kit) only once; a second create returns `422`.

### Kit

`name` (required), `description`, `season`. `GET /kits/:id.json` also returns `weight` and
`kit_items`.

### Meal

| Field | Type | Notes |
|---|---|---|
| `name` | string, required | |
| `brand` | string | |
| `meal_type` | `breakfast` \| `lunch` \| `dinner` \| `snack` | Default `dinner` |
| `calories` | integer ≥ 0 | Per serving |
| `weight_grams` | integer ≥ 0 | Per serving |
| `rating` | integer 1–5, or `null` | |
| `would_buy_again` | boolean, or `null` for undecided | |
| `notes` | string | |

Read-only: `calories_per_100g`. A trip meal takes `meal_id`, `quantity` and `notes`.

### Reference list

`name` (required), `author`, `source_url` (must be `http(s)://…`), `notes`. Its items are
plain rows, not inventory: `name`, `manufacturer`, `category` (required), `weight_grams`,
`quantity`, `worn`, `consumable`, `notes`. `GET /reference_lists/:id.json` also returns
`weight` and `reference_items`.

## Weights

A line's weight is decided in this order, and the API reports the result as
`line_weight_grams`:

1. The trip line's `weight_grams_override`, if set, as-is.
2. The item's `unit_weight_grams` × quantity, if it is a per-unit item.
3. The item's `measured_weight_grams`, else its `weight_grams`, × quantity. Neither set
   counts as 0.

Trips, kits and reference lists return a `weight` object:

```json
{ "base_grams": 920, "worn_grams": 700, "consumable_grams": 202.5, "total_grams": 1822.5,
  "by_category": { "Food": 2.5, "Footwear": 700, "Fuel": 200, "Kitchen": 50, "Shelter": 870 } }
```

Each line counts as **worn** if the line is worn, else **consumable** if the item is
consumable, else **base**. Category never decides this: a water bottle filed under Water
is base weight. See `docs/adr/20260926-consumable-is-an-item-flag.md`.

## Common tasks

Add gear:

```sh
curl -s -X POST "$PIKA/items.json" -H 'Content-Type: application/json' \
  -d '{"item": {"name": "Example Tent", "category": "Shelter", "weight_grams": 900}}'
```

Record what it actually weighs:

```sh
curl -s -X PATCH "$PIKA/items/12.json" -H 'Content-Type: application/json' \
  -d '{"item": {"measured_weight_grams": 870}}'
```

Plan a trip from a kit, then adjust:

```sh
curl -s -X POST "$PIKA/trips.json" -H 'Content-Type: application/json' \
  -d '{"trip": {"name": "Example Loop", "starts_on": "2026-07-10", "ends_on": "2026-07-12"}}'

# Copies the kit's lines. Items already on the trip are left alone, so this can be
# repeated with another kit to top up. Returns the trip.
curl -s -X POST "$PIKA/trips/3/pack.json" -H 'Content-Type: application/json' -d '{"kit_id": 1}'

curl -s -X POST "$PIKA/trips/3/trip_items.json" -H 'Content-Type: application/json' \
  -d '{"trip_item": {"item_id": 12, "quantity": 2}}'
```

Load someone else's list to compare against:

```sh
curl -s -X POST "$PIKA/reference_lists.json" -H 'Content-Type: application/json' \
  -d '{"reference_list": {"name": "Example Ultralight List", "author": "Example Author"}}'

curl -s -X POST "$PIKA/reference_lists/1/reference_items.json" -H 'Content-Type: application/json' \
  -d '{"reference_item": {"name": "Example Tarp", "category": "Shelter", "weight_grams": 300}}'
```

### Loading data idempotently

The API has no upsert. A loader that may be re-run should `GET` the collection first,
match on name (plus manufacturer or brand), then `PATCH` a match or `POST` a new record.
