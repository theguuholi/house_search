---
status: pending
title: Implement request, criteria, and case lifecycle
type: backend
complexity: critical
---

# Task 4: Implement request, criteria, and case lifecycle

## Overview
Deliver persisted request drafts, deterministic criteria validation, confirmation, transparent case opening, research-run foundations, and seven-day refinement. Broker LiveViews must recover from reconnects and stale tabs while composing account authorization and usage consumption into auditable commands.

<critical>
- ALWAYS READ the PRD, the TechSpec, and their catalogs (`_user_stories.md`, `_tests.md`) before starting
- REFERENCE TECHSPEC for implementation details — do not duplicate here
- FOCUS ON "WHAT" — describe what needs to be accomplished, not how
- MINIMIZE CODE — show code only to illustrate current structure or problem areas
- TESTS REQUIRED — implement every test case assigned in ## Tests
</critical>

<requirements>
- Draft messages, interpretations, confirmations, openings, and refinements MUST be persisted, account-scoped, versioned, stale-safe, and idempotent.
- Criteria MUST support only the documented pilot vocabulary, preserve hard/preference classification, validate cross-field constraints, and treat unknown distinctly from a match.
- Confirmation MUST reject unresolved clarification, incomplete review, stale/discarded drafts, invalid criteria, and suspended actors before calling Usage.
- Case opening MUST atomically persist the case, criteria version, research run, usage effects, and exactly one initial orchestration enqueue contract.
- Refinement MUST create new immutable criteria/research versions without a usage event before the exact seven-day boundary and MUST preserve the prior current version when unconfirmed or invalid.
- LiveViews MUST rebuild from persisted state, preserve editor input on errors, and expose stable non-leaking error categories.
- All new business timestamps MUST use injected UTC time and `utc_datetime_usec` without rewriting generated auth timestamp semantics.
</requirements>

## Subtasks
- [ ] 4.1 Add draft, message, interpretation, case, criteria-version, research-run, refinement-draft, and command-receipt persistence.
- [ ] 4.2 Implement the versioned criteria schema, normalization, pilot-boundary validation, limits, and preference-only acknowledgment.
- [ ] 4.3 Implement account-scoped draft/message/review/confirmation APIs with optimistic concurrency and idempotency.
- [ ] 4.4 Compose confirmed case opening with locked Usage quote/consumption and one orchestration enqueue seam.
- [ ] 4.5 Implement seven-day refinement drafts, reconfirmation, version history, and expiry/new-case handoff.
- [ ] 4.6 Deliver request, base case, and refinement LiveViews with persisted reconnect behavior.
- [ ] 4.7 Add case/criteria fixtures, injected clocks, sandbox concurrency barriers, and stable command-error coverage.

## Implementation Details
Place the foundational criteria contract at `HouseSearch.Ranking.Criteria` so Task 05 consumes it without replacing it. The TechSpec does not specify numeric request/criterion limits or a universal command-receipt model; centralize explicit documented limits and persist replay results consistently rather than scattering guesses.

### Relevant Files
- `lib/house_search/search_cases.ex` — public draft, opening, refinement, and projection APIs.
- `lib/house_search/search_cases/request_draft.ex` — account-scoped mutable draft and lock version.
- `lib/house_search/search_cases/draft_message.ex` — stable message order and client-message idempotency.
- `lib/house_search/search_cases/draft_interpretation.ex` — proposed criteria or one clarification with audit fields.
- `lib/house_search/search_cases/search_case.ex` — ownership, original confirmation, and refinement expiry.
- `lib/house_search/search_cases/criteria_version.ex` — immutable classified criteria versions.
- `lib/house_search/search_cases/research_run.ex` — per-version research state and deadline.
- `lib/house_search/search_cases/case_view.ex` — persisted projection for reconnects.
- `lib/house_search/ranking/criteria.ex` — validated criteria vocabulary and serialization.
- `lib/house_search_web/live/request_live.ex` — intake, review, quote, and opening UI.
- `lib/house_search_web/live/refinement_live.ex` — refinement lifecycle UI.
- `lib/house_search_web/live/case_live.ex` — base persisted case view for later enrichment.

### Dependent Files
- `lib/house_search/accounts/authorization.ex` — supplies actor/account/suspension enforcement.
- `lib/house_search/usage.ex` — supplies locked quote and composable consumption contracts.
- `lib/house_search/ranking.ex` — later evaluates immutable confirmed criteria and property views.
- `lib/house_search/ai.ex` — later fills validated draft interpretations through the public boundary.
- `lib/house_search/workers/research_orchestrator_worker.ex` — later implements the enqueue seam and durable flow.
- `test/support/fixtures/search_cases_fixtures.ex` — shared downstream case/version fixtures.

### Related ADRs
- [ADR-002: Confirmed Criteria and Supported Pilot Inventory](adrs/adr-002.md) — directly governs criteria and confirmation.
- [ADR-003: Invite-Only Pilot and Transparent Usage Charging](adrs/adr-003.md) — governs billable opening and free refinement.
- [ADR-004: Phoenix Modular Monolith with Durable Oban Orchestration](adrs/adr-004.md) — governs persisted state and transaction boundaries.
- [ADR-005: Generated Authentication with Account Memberships and Invitations](adrs/adr-005.md) — governs account authorization and suspension.
- [ADR-006: Provider-Neutral Sagents Boundary](adrs/adr-006.md) — constrains the later interpretation integration.

## Deliverables
- Versioned draft, criteria, case, research-run, refinement, and command-replay persistence.
- Deterministic criteria validation and pilot inventory boundary.
- Atomic, usage-aware, idempotent case-opening contract.
- Persisted broker intake, case, and refinement LiveViews.
- Every test case assigned in `## Tests` implemented and passing **(REQUIRED)**

## Tests

Cases assigned from `_tests.md`, the test contract — read each ID's full definition there before writing tests.

- [ ] UT-024, UT-025, UT-026, UT-027, UT-028 — criteria validation, limits, supported inventory, acknowledgment, and serialization.
- [ ] UT-043, UT-044, UT-045, UT-046, UT-047 — persisted case projection, refinement boundary, state prerequisites, stale commands, and replay.
- [ ] IT-022, IT-023, IT-024, IT-025, IT-026, IT-027, IT-028 — blank/length/auth/message concurrency/reconnect/retry/clarification intake behavior.
- [ ] IT-031, IT-032, IT-033, IT-034, IT-035, IT-036, IT-037, IT-038, IT-039, IT-040 — criteria confirmation validation, authorization, staleness, reconnect, replay, and large versions.
- [ ] IT-041, IT-042, IT-043, IT-044, IT-045, IT-046, IT-047, IT-048, IT-049, IT-050 — usage-aware opening, concurrency, reconnect, replay, and large history.
- [ ] IT-101, IT-102, IT-103, IT-104, IT-105, IT-106, IT-107, IT-108, IT-109, IT-110 — refinement validation, expiry, authorization, concurrency, replay, sharing boundary, and history.
- [ ] E2E-005 — included, paid-overage, retry, and exhausted-trial case authorization journey.

## Success Criteria
- Every assigned test case implemented and passing
- A confirmed opening has exactly one case, criteria version, usage effect, research run, and enqueue result.
- Reconnects and stale tabs always resolve from current persisted state.
- In-window refinement creates a new auditable version without another ledger event.

