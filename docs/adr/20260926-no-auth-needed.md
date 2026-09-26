# 20260926 — No authentication

## Context

Pika holds one person's gear, trips and meals. Nothing in the app differs between two people
looking at it, so there is no view that needs to know who is asking.

The intended deployment is a private network address, reachable from inside a home or over a
private tunnel, and not from the internet. The JSON API accepts writes from scripts and
agents that cannot do interactive sign-in.

## Decision

No authentication, on the API or the web UI. No `User` model, no login, no trust of
proxy-injected identity headers.

## Consequences

- Loaders and agents call the API with no credential to store or rotate.
- Anything on the same network can edit the inventory. The realistic worst case is a wrong
  weight, which is acceptable for this data and would not be for anything of consequence.
- The app must never be deployed anywhere publicly reachable. `compose.yaml` says so in its
  header; the app does not enforce it.
- Storing captured purchase emails raises the stakes: they carry an address and order
  details. That is still household data on a private network, but it is the point to revisit
  if the app is ever reachable more widely or holds more than one person's data.

## Alternatives considered

- **A shared bearer token on write endpoints.** Rejected: a secret in two places, protecting
  against an attacker already inside the network.
- **Forward-auth in front of the whole app.** Rejected: it breaks every machine caller, and
  the bypass that unbreaks them reinstates the exposure with more moving parts.
