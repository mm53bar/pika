# 20260926 — Purchase intake from a shared mailbox, claimed only after the LLM confirms

## Context

Gear purchases arrive as order confirmations, receipts and shipping notices, usually in a
personal mailbox. The owner forwards them to a household address that several apps already
read. Each app takes what it recognises and moves it into its own folder; whatever is left
in INBOX belongs to nobody yet.

Two things make that harder for gear than for most mail:

1. **Order language is generic.** "Your order is confirmed", "confirmation number",
   "receipt" and "arrives Tuesday" appear in gear orders, travel bookings, bills and
   subscriptions alike. A keyword filter tuned to catch every gear order will also catch a
   ferry receipt.
2. **Taking the wrong message is silent.** A message moved into Pika's folder disappears from
   the inbox the other apps read. The app it belonged to never sees it, and nothing reports
   that.

An LLM reads these emails well. Tested against a live model with invented messages, it
turned forwarded orders into clean lines (brand separated from product, gift cards,
shipping and "you might also like" skipped, sizes kept out of weights), and rejected a
ferry receipt and a subscription bill as not gear.

## Decision

Two passes, and the second one decides.

- `PurchaseEmailClassifier` is a cheap filter over header and body: a known retailer's
  address or domain, order phrases, and order words. It only decides what is worth an LLM
  call, so it errs towards flagging.
- `GearTriager` asks the LLM whether this is a purchase of physical gear and, if so, for the
  lines bought. **A message is moved into Pika's folder only once it is known to be Pika's**
  (`InboundEmail#claimable?`): the LLM confirmed it, a human has handled it, or the LLM
  failed every retry but a known retailer sent it.
- If the LLM says it is not gear, the email is recorded as `not_gear`, left where it is, and
  never read or moved again.
- If the LLM is unreachable the message stays in INBOX and is retried on later passes, up to
  three attempts.

The IMAP rules come from the sibling app that established this mailbox pattern: fetch with
`BODY.PEEK[]` so read state is never touched, move only into Pika's own folder, and capture
before moving so a failure leaves the message where it was. As there, no per-app address:
the classifier and the LLM route mail, so a single forwarding address works.

Nothing is added to the inventory automatically. Each email waits in the Inbox with its
proposed lines until a human adds (optionally editing, or dropping lines) or ignores it.

## Consequences

- Pika cannot take another app's mail by accident, even when the keyword filter misfires.
  This is only half of coexistence: another reader of the same mailbox with a broader
  filter can still take gear orders before Pika sees them. That is for that reader to fix.
- Every flagged message costs an LLM call, a few seconds each. At household volumes this is
  nothing.
- A long LLM outage leaves gear emails in the shared inbox rather than in Pika. Retrying from
  the Inbox page resets the attempts.
- Without an LLM configured, intake captures but claims nothing and proposes nothing.
- Review before adding keeps a misread line out of the inventory, at the cost of a click per
  order. Automatic adding for high-confidence reads can come later without changing this
  flow.
- Weights are taken only when the email states one or the model is confident of the
  manufacturer's published figure, and are stored as the *listed* weight. A kitchen-scale
  weight still overrides it.

## Alternatives considered

- **Claim on the keyword filter, as soon as it matches.** Rejected: it would take travel
  receipts and bills from the apps they belong to, silently.
- **A dedicated address per app.** Rejected for the same reason the sibling app rejected it:
  it asks a human to route mail that the software can route, and becomes a table of
  addresses to remember.
- **Add items automatically.** Deferred: a wrong item in the inventory is worse than a click,
  until there is a record of how often the reads are right.
