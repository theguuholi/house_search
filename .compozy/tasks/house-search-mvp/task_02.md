---
status: pending
title: Build usage plans and immutable ledger
type: backend
complexity: critical
---

# Task 2: Build usage plans and immutable ledger

## Overview
Deliver the account-owned plans, billing periods, transparent quotes, overage consent, and append-only usage ledger. This slice makes usage consequences auditable and concurrency-safe while exposing a composable transaction contract for later case opening and failure-credit orchestration.

<critical>
- ALWAYS READ the PRD, the TechSpec, and their catalogs (`_user_stories.md`, `_tests.md`) before starting
- REFERENCE TECHSPEC for implementation details — do not duplicate here
- FOCUS ON "WHAT" — describe what needs to be accomplished, not how
- MINIMIZE CODE — show code only to illustrate current structure or problem areas
- TESTS REQUIRED — implement every test case assigned in ## Tests
</critical>

<requirements>
- Trial and Founding Plan quotes MUST implement the documented durations, allowances, BRL amounts, expiry, and explicit-overage rules.
- The ledger MUST be append-only; balances and totals MUST be derived from immutable events rather than mutable counters.
- Quote commitment MUST lock and re-evaluate the active billing state and return `:usage_changed` before insertion when the rendered quote is stale.
- Consumption, overage consent, and credits MUST have unique business idempotency and causation constraints and affect balances exactly once.
- `consume_multi/2` MUST compose into the later case-opening transaction without cross-context table queries.
- Credit APIs MUST distinguish terminal zero-result technical failure from legitimate empty and partial/verified outcomes.
- Usage history and reconciliation MUST use stable cursor pagination and bounded aggregate queries.
</requirements>

## Subtasks
- [ ] 2.1 Add subscription, billing-period, authorization, usage-event, and audit-conflict persistence with business constraints.
- [ ] 2.2 Implement quote, balance, period-boundary, and remaining-allowance calculations.
- [ ] 2.3 Implement locked quote commitment and composable consumption/overage `Ecto.Multi` contracts.
- [ ] 2.4 Implement idempotent credit eligibility and append-only credit APIs for later workers.
- [ ] 2.5 Deliver broker allowance projection and administrator usage/reconciliation LiveView.
- [ ] 2.6 Add cursor-paginated usage history and large-ledger aggregate queries.
- [ ] 2.7 Add deterministic usage fixtures, boundary clocks, and concurrency tests.

## Implementation Details
Create a dedicated `HouseSearch.Usage` context. Coordinate the `usage_events.case_id` migration contract with Task 04 so required attribution remains enforceable; use public `Ecto.Multi` composition rather than direct SearchCases schema access.

### Relevant Files
- `lib/house_search/usage.ex` — public quote, consume, credit, balance, and reconciliation APIs.
- `lib/house_search/usage/subscription.ex` — plan lifecycle and active-account constraint.
- `lib/house_search/usage/billing_period.ex` — immutable allowance snapshot and quote version locking.
- `lib/house_search/usage/usage_authorization.ex` — criteria fingerprint and explicit consent.
- `lib/house_search/usage/usage_event.ex` — append-only ledger event and causation constraints.
- `lib/house_search_web/live/admin/usage_live.ex` — cross-account reconciliation surface.
- `lib/house_search_web/router.ex` — authenticated administrator usage route.
- `test/support/fixtures/usage_fixtures.ex` — periods, quotes, events, boundaries, and large histories.

### Dependent Files
- `lib/house_search/accounts.ex` — supplies account and active/admin actor contracts.
- `lib/house_search/search_cases.ex` — composes confirmed case creation with usage consumption.
- `lib/house_search/workers/credit_failed_case_worker.ex` — calls the exactly-once credit API.
- `lib/house_search_web/live/broker_dashboard_live.ex` — renders the current plan and allowance.
- `test/support/data_case.ex` — concurrency tests require separate SQL Sandbox owners/barriers.

### Related ADRs
- [ADR-002: Confirmed Criteria and Supported Pilot Inventory](adrs/adr-002.md) — criteria confirmation precedes consumption.
- [ADR-003: Invite-Only Pilot and Transparent Usage Charging](adrs/adr-003.md) — directly defines plans, overages, refinement, and credits.
- [ADR-004: Phoenix Modular Monolith with Durable Oban Orchestration](adrs/adr-004.md) — governs public APIs and later durable credit jobs.
- [ADR-005: Generated Authentication with Account Memberships and Invitations](adrs/adr-005.md) — accounts own subscriptions and ledger entries.

## Deliverables
- Immutable usage persistence, quote versioning, ledger aggregation, and exactly-once constraints.
- Public quote, consumption, consent, balance, history, reconciliation, and credit contracts.
- Broker allowance projection and administrator reconciliation UI.
- Migration-safe case attribution contract documented for Task 04.
- Every test case assigned in `## Tests` implemented and passing **(REQUIRED)**

## Tests

Cases assigned from `_tests.md`, the test contract — read each ID's full definition there before writing tests.

- [ ] UT-037, UT-038, UT-039, UT-040, UT-041, UT-042 — quote boundaries, ledger validation/math, stale quotes, and exactly-once events.
- [ ] IT-111, IT-112, IT-113, IT-114, IT-120 — invalid attribution, empty state, period boundaries, authorization, and large-ledger reconciliation.
- [ ] E2E-001 — invited broker activation through visible trial allowance, suspension, restoration, and preserved history.

## Success Criteria
- Every assigned test case implemented and passing
- Included, overage, blocked, and credit balances are reproducible solely from ledger events.
- Concurrent quote/consume and duplicate credit attempts produce exactly one balance effect.
- Administrator and broker views agree on the same account-period totals.
