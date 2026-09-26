# 20260926 — Browser tests for the searchable select

Amends `20260926-integration-tests-over-system-tests.md`.

## Context

That decision kept the suite to Rack-level integration tests because no page had behaviour a
request couldn't exercise, and named the trigger for reconsidering: a page growing JavaScript
with real logic.

The category field was a text input with a `<datalist>`. Browsers filter a datalist by the
field's current value, so on an item that already had a category the dropdown offered only
that one. It was replaced with a searchable, creatable select (Rails Blocks, on Tom Select):
click to see every category, type to filter, or add a new one in place. That behaviour lives
entirely in the browser. An integration test sees a plain `<select>` and would pass with the
JavaScript broken or missing.

## Decision

System tests exist for this component only, driven by Cuprite (Chrome over its DevTools
protocol, with no separate driver). They cover the regression that prompted it — opening the
picker on an item that has a category lists all of them — plus filtering, choosing and
creating. They run in `bin/ci` and in GitHub Actions, where the runner image ships Chrome.

Everything else stays a Rack integration test. A new system test needs a behaviour that only
a browser can show.

## Consequences

- `bin/ci` needs Chrome installed. It takes a few seconds longer.
- The select is vendored code (controller, partial, styles) credited in the README. Tom Select
  is pinned as its single-file build behind a two-line module, because the split ES-module
  build importmap downloads imports its own files by relative path, which does not resolve.
- `dark:` variants apply only under a `.dark` class Pika never sets, so the component's dark
  styles don't follow the OS on an otherwise light page.

## Alternatives considered

- **A plain `<select>` plus a "new category" text box.** Works with no JavaScript and stays
  testable at the Rack level; rejected in favour of the smoother picker.
- **Clearing the datalist input on focus.** A trick that shows every option, but it fights
  the browser and loses the value when nothing is picked.
