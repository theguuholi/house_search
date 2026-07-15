---
status: pending
title: Build ranking and broker-controlled recommendations
type: backend
complexity: critical
---

# Task 5: Build ranking and broker-controlled recommendations

## Overview
Implement deterministic ranking, exact/near-match separation, versioned shortlist control, evidence projection, broker feedback, exact-first replacement, readiness, and client-ready summaries. The broker remains responsible for every compromise and client-facing option, and all factual output remains usable without AI.

<critical>
- ALWAYS READ the PRD, the TechSpec, and their catalogs (`_user_stories.md`, `_tests.md`) before starting
- REFERENCE TECHSPEC for implementation details — do not duplicate here
- FOCUS ON "WHAT" — describe what needs to be accomplished, not how
- MINIMIZE CODE — show code only to illustrate current structure or problem areas
- TESTS REQUIRED — implement every test case assigned in ## Tests
</critical>

<requirements>
- Ranking `v1` MUST be pure, deterministic, bounded 0–100, exact-before-near, and use the ADR-defined weights and tie order.
- Unknown values MUST fail hard eligibility where applicable, earn no preference credit, and never appear as positive reasons.
- Near matches MUST retain every evidenced failed hard requirement and MUST require explicit compromise approval before entering an open position.
- Shortlist mutations MUST lock/version current state, contain at most three distinct available clusters, exclude rejected clusters, and never silently admit a near match.
- Every displayed recommendation fact MUST project current verified evidence, safe link, provenance, verification time, unknowns, and compromises.
- Summaries MUST bind one ready shortlist version, exclude broker/operator details and client identity, and become visibly stale after later changes.
- Feedback and summary commands MUST be idempotent and return stable stale/not-found behavior under concurrent or cross-account actions.
</requirements>

## Subtasks
- [ ] 5.1 Implement immutable ranking inputs/results, eligibility, near failures, score breakdown, stable tie order, and bounded pagination.
- [ ] 5.2 Add match snapshots, shortlist versions/entries, near approvals, feedback, and summary persistence with constraints.
- [ ] 5.3 Implement recomputation persistence and exact/near shortlist selection through SearchCases public APIs.
- [ ] 5.4 Implement locked near-match approval, readiness, feedback, exclusion, and exact-first replacement commands.
- [ ] 5.5 Implement bounded evidence/recommendation projections and deterministic factual reasons.
- [ ] 5.6 Implement version-bound client-ready summary generation and staleness/content policy.
- [ ] 5.7 Extend `CaseLive` with accessible recommendation, evidence, approval, feedback, readiness, and copy surfaces.
- [ ] 5.8 Add ranking property tests and recommendation/summary/feedback integration fixtures.

## Implementation Details
Ranking must accept immutable structs and have no Ecto or AI dependency. Summary copy limit, feedback-note limit, cursor page size, and any evidence-view route are not numerically fixed by the specs; define named documented contracts and a verified LiveView route/action rather than hiding magic values.

### Relevant Files
- `lib/house_search/ranking.ex` — pure eligibility, scoring, ordering, and pagination.
- `lib/house_search/ranking/candidate.ex` — immutable input projection.
- `lib/house_search/search_cases/match_snapshot.ex` — persisted ranked outcome and evidence watermark.
- `lib/house_search/search_cases/shortlist_version.ex` — immutable shortlist version/readiness state.
- `lib/house_search/search_cases/shortlist_entry.ex` — rank, kind, approval, compromise, and source snapshot.
- `lib/house_search/search_cases/near_match_approval.ex` — explicit compromise approval and replay key.
- `lib/house_search/search_cases/recommendation_feedback.ex` — verdict/reason/note/current-state contract.
- `lib/house_search/search_cases/summary_snapshot.ex` — version-bound immutable client content.
- `lib/house_search/search_cases/summary.ex` — deterministic content policy and renderer.
- `lib/house_search_web/live/case_live.ex` — broker-controlled recommendation workflow.

### Dependent Files
- `lib/house_search/ranking/criteria.ex` — Task 04 confirmed-criteria contract.
- `lib/house_search/listings.ex` — Task 03 property/evidence/cluster public projections.
- `lib/house_search/search_cases.ex` — owns persistence and command transactions.
- `lib/house_search/ai.ex` — later consumes the evidence projection only for optional narrative.
- `lib/house_search/workers/recompute_research_worker.ex` — later invokes ranking/recomputation durably.
- `test/support/fixtures/listings_fixtures.ex` — provides current evidence and provenance fixtures.

### Related ADRs
- [ADR-001: Broker-Controlled Evidence-Backed Shortlists](adrs/adr-001.md) — directly governs shortlist and approval behavior.
- [ADR-002: Confirmed Criteria and Supported Pilot Inventory](adrs/adr-002.md) — confirmed classifications govern eligibility and scoring.
- [ADR-004: Phoenix Modular Monolith with Durable Oban Orchestration](adrs/adr-004.md) — requires persisted-before-broadcast public APIs.
- [ADR-006: Provider-Neutral Sagents Boundary](adrs/adr-006.md) — AI cannot affect ranking or evidence integrity.
- [ADR-007: Versioned Deterministic Ranking Formula](adrs/adr-007.md) — directly defines ranking `v1`.
- [ADR-008: Explicit Source Adapters and Bounded Evidence Retention](adrs/adr-008.md) — evidence survives raw-response deletion.

## Deliverables
- Pure deterministic ranking `v1` with property-based invariants and persisted breakdowns.
- Versioned shortlist, near approval, feedback/replacement, readiness, evidence, and summary behavior.
- Broker recommendation UI with accessible exact/near separation and non-leaking stale/error handling.
- Deterministic factual recommendations and client-ready content independent of AI availability.
- Every test case assigned in `## Tests` implemented and passing **(REQUIRED)**

## Tests

Cases assigned from `_tests.md`, the test contract — read each ID's full definition there before writing tests.

- [ ] UT-029, UT-030, UT-031, UT-032, UT-033, UT-034, UT-035, UT-036 — eligibility, unknowns, bounds, compromise evidence, clustering-facing behavior, and stable ordering.
- [ ] UT-053, UT-054, UT-055, UT-056, UT-057, UT-058, UT-059, UT-060, UT-061, UT-062 — summary policy/versioning and feedback/replacement validation/idempotency.
- [ ] IT-061, IT-062, IT-063, IT-064, IT-065, IT-066, IT-067, IT-068, IT-069, IT-070, IT-071, IT-072, IT-073, IT-074 — shortlist, approval, deterministic order, evidence safety, authorization, and bounded views.
- [ ] IT-078, IT-080, IT-081, IT-082, IT-083, IT-084, IT-085, IT-086, IT-087, IT-088, IT-090 — pending/deep evidence, history, and client-summary lifecycle.
- [ ] IT-091, IT-092, IT-093, IT-094, IT-095, IT-096, IT-097, IT-098, IT-099, IT-100 — feedback validation, concurrency, replay, and exact-first replacement.
- [ ] E2E-004, E2E-007, E2E-009, E2E-010 — confirmed-criteria eligibility, exact/near control, client sharing, and feedback/replacement journeys.

## Success Criteria
- Every assigned test case implemented and passing
- Identical criteria/data/ranking version always returns the same ordered shortlist.
- No near match or unavailable/rejected property enters client content without the required broker action.
- Every positive reason and summary fact resolves to current verified evidence.

