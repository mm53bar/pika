# 20260926 — No personal data in this repository

## Context

This repository is public, so other people can run Pika for their own gear. That makes seeded
example data a disclosure question rather than a convenience question.

A gear inventory looks harmless and isn't. It says what someone owns and what it cost, and a
trip record says where they will be, on which nights, alone or not, and who to call if they
don't come back. Purchase emails add order numbers and a shipping address. A seeded install
would publish all of that.

Git history compounds it. A repository that is cleaned up before being made public still
exposes every commit ever made to it, so the cleanup has to have happened already.

The same reasoning covers infrastructure: naming the proxy, container manager or NAS a
deployment uses is reconnaissance material about a private network.

## Decision

Nothing in this repository describes a real person, their gear, their trips or their network.

- `db/seeds.rb` seeds nothing and says why.
- Inventory, trip, kit and meal fixtures are placeholders (`Example Tent`) and say so at the
  top of each file. Test and documentation examples are invented, never adapted from a real
  inventory — a real item described generically is still that person's item.
- Reference-list fixtures are invented too. A real list someone else wrote is theirs to
  publish; many are distributed to subscribers rather than posted openly, and copying one
  into a public repo republishes it.
- `compose.yaml` is a template carrying placeholder values only.
- Real data is loaded over the JSON API after deployment, by tooling kept outside this
  repository.

This holds from the first commit.

## Consequences

- The app is developed and tested against invented data, which also proves it works for
  somebody other than its author.
- Loading real data needs full resourceful create/update over JSON on every model. It has it.
- The loader must be idempotent so the data file can be edited and re-run. That belongs to
  the loader, not to this app.
- Deployment-specific facts belong in the deployer's private notes, not in `docs/`.

## Alternatives considered

- **Seed real data and keep the repository private.** Rejected: it forecloses anyone else
  using it, and history makes the decision permanent.
- **Scrub before publishing.** Rejected: history rewrites are error-prone and fail silently
  once a clone exists.
