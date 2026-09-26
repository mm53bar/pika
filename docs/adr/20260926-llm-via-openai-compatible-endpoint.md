# 20260926 — LLM features via an OpenAI-compatible endpoint, configured by env

## Context

Reading what was bought out of an order email needs an LLM. This repo is public and ships
in a Docker image, so it can't carry a provider, endpoint, model or key — and different
deployments will want different backends (a local Ollama, a cloud model, or another
provider).

## Decision

- **One integration surface: the OpenAI-compatible `/v1/chat/completions` API.**
  `LlmClient` (plain `Net::HTTP`) targets it with `response_format: json_object`. Ollama —
  local and cloud — speaks this, as do most providers, so the same code works everywhere and
  the **model name** selects the backend.
- **All configuration is env:** `LLM_BASE_URL`, `LLM_MODEL`, optional `LLM_API_KEY`. The
  repo and compose template carry placeholders only. Unconfigured → `LlmClient#configured?`
  is false and purchase intake claims and proposes nothing.
- **Unreachable is not the same as unusable.** `LlmClient::Unavailable` (timeouts, refused
  connections, 5xx) is retried on a later intake pass. An answer that parses but makes no
  sense returns `nil` and counts as a failed read.
- **Human-in-the-loop.** `GearTriager` proposes lines; they are shown for review and only
  become items when a human adds them.

## Consequences

- Deployments point `LLM_BASE_URL` at whatever they run and pick a model; changing backend
  is configuration, not code.
- No SDK or provider lock-in, and no secrets in the repo.
- The prompt is tuned to the model it was tested with. Swapping models is a config change,
  but worth re-testing the prompt against the new one.

## Alternatives considered

- **A provider SDK.** Rejected: more dependency than a single JSON POST needs, and it would
  still be reconfigured per deployment.
- **Ollama's native `/api/chat`.** Rejected in favour of the OpenAI-compatible path so other
  backends work unchanged.
