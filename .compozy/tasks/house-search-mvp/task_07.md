---
status: pending
title: Orchestrate durable progressive research
type: backend
complexity: critical
---

# Task 7: Orchestrate durable progressive research

## Overview
Integrate every prior domain through durable Oban orchestration, progressive persisted recomputation, deadline finalization, PubSub invalidation, availability handling, technical-failure credits, and raw-response retention. This final slice proves restart-safe behavior and complete broker/admin flows under partial failure and large fixtures.

<critical>
- ALWAYS READ the PRD, the TechSpec, and their catalogs (`_user_stories.md`, `_tests.md`) before starting
- REFERENCE TECHSPEC for implementation details — do not duplicate here
- FOCUS ON "WHAT" — describe what needs to be accomplished, not how
- MINIMIZE CODE — show code only to illustrate current structure or problem areas
- TESTS REQUIRED — implement every test case assigned in ## Tests
</critical>

<requirements>
- Oban MUST run under the application with distinct bounded queues and database-backed jobs for orchestration, collection, normalization, recomputation, finalization, credit, and retention.
- Every worker MUST use public context APIs, persist progress before broadcasting, and be replay-safe through business keys and database constraints.
- Research MUST show verified local results first, refresh only eligible stale active sources, isolate source failures/rate limits, and remain recoverable after browser/application restart.
- PubSub MUST carry invalidations only; `CaseLive` MUST reload PostgreSQL state on mount and every event without losing local broker input/focus.
- Deadline finalization MUST lock the run, preserve immutable terminal state, and classify complete/partial/empty/failed from persisted source outcomes and verified count.
- Listing unavailability MUST recompute into a new shortlist version, preserve history/evidence/summaries, and never auto-admit a near match.
- Only terminal zero-verified technical failure MUST receive exactly one credit; legitimate empty and any verified result MUST remain billable.
- Raw sanitized bodies MUST expire after 30 days while hashes, metadata, snapshots, and field evidence remain.
</requirements>

## Subtasks
- [ ] 7.1 Add Oban dependency, migration, supervision, queue configuration, and deterministic test modes.
- [ ] 7.2 Implement research orchestration and source-attempt/page collection workers with bounded fan-out and rate handling.
- [ ] 7.3 Implement normalization and idempotent listing/evidence persistence workers.
- [ ] 7.4 Implement persisted ranking recomputation, shortlist mutation, and post-commit PubSub invalidation.
- [ ] 7.5 Implement ten-minute locked finalization and terminal outcome classification.
- [ ] 7.6 Implement exactly-once failure-credit and late-result conflict handling.
- [ ] 7.7 Implement daily raw-response retention and scheduled stale-source refresh.
- [ ] 7.8 Complete progressive `CaseLive`, source-status, reconnect, pagination, and accessibility behavior.
- [ ] 7.9 Add business telemetry/log filtering and the large/concurrent/restart integration fixtures.

## Implementation Details
Oban uniqueness is an enqueue optimization only; business idempotency belongs in domain constraints and command keys. Preserve the existing `HouseSearch.PubSub` and `HouseSearch.Finch` supervision, and add Oban without silently changing generated auth timestamps.

### Relevant Files
- `mix.exs` — add Oban OSS and required test support dependencies.
- `lib/house_search/application.ex` — supervise configured Oban alongside Repo/PubSub/Finch.
- `config/config.exs` — bounded queues and plugins.
- `config/test.exs` — manual/inline Oban testing modes.
- `lib/house_search/workers/research_orchestrator_worker.ex` — local-first fan-out and scheduling.
- `lib/house_search/workers/source_collection_worker.ex` — bounded source/page attempts.
- `lib/house_search/workers/normalization_worker.ex` — evidence persistence and recompute enqueue.
- `lib/house_search/workers/recompute_research_worker.ex` — persisted ranking/shortlist updates.
- `lib/house_search/workers/finalize_research_worker.ex` — deadline and immutable terminal state.
- `lib/house_search/workers/credit_failed_case_worker.ex` — exactly-once eligible credit.
- `lib/house_search/workers/raw_response_retention_worker.ex` — 30-day sanitized-body expiry.
- `lib/house_search/search_cases/events.ex` — stable invalidation topics and post-commit broadcasts.
- `lib/house_search_web/live/case_live.ex` — persisted progressive/reconnect UI.

### Dependent Files
- `lib/house_search/sources.ex` — eligible coverage, status, limits, and attempts.
- `lib/house_search/ingestion.ex` — adapter, safe retrieval, normalization, and raw-response APIs.
- `lib/house_search/listings.ex` — current property/evidence, availability, and retention APIs.
- `lib/house_search/search_cases.ex` — opening/refinement enqueue seams and persisted projections.
- `lib/house_search/ranking.ex` — pure deterministic recomputation.
- `lib/house_search/usage.ex` — credit eligibility, ledger, and audit-conflict APIs.
- `lib/house_search/ai.ex` — retry-classified optional interpretation/narrative boundary.
- `lib/house_search_web/telemetry.ex` — stable low-cardinality business metrics.

### Related ADRs
- [ADR-001: Broker-Controlled Evidence-Backed Shortlists](adrs/adr-001.md) — availability cannot silently admit near matches.
- [ADR-003: Invite-Only Pilot and Transparent Usage Charging](adrs/adr-003.md) — directly governs refinement and failure credits.
- [ADR-004: Phoenix Modular Monolith with Durable Oban Orchestration](adrs/adr-004.md) — directly governs this slice.
- [ADR-007: Versioned Deterministic Ranking Formula](adrs/adr-007.md) — recomputation must preserve ranking version and order.
- [ADR-008: Explicit Source Adapters and Bounded Evidence Retention](adrs/adr-008.md) — governs retrieval and retention jobs.

## Deliverables
- Configured Oban runtime with bounded durable workers for the complete research lifecycle.
- Persisted-first progressive recomputation, invalidation-only PubSub, and restart-safe `CaseLive`.
- Locked deadline classification, availability recomputation, exactly-once credits, and late-result conflict audit.
- Raw-response retention, scheduled refresh, observability, and large-fixture verification.
- Every test case assigned in `## Tests` implemented and passing **(REQUIRED)**

## Tests

Cases assigned from `_tests.md`, the test contract — read each ID's full definition there before writing tests.

- [ ] IT-013, IT-019, IT-020 — rate-limited job execution, source deactivation during research, and bounded high-volume collection.
- [ ] IT-051, IT-052, IT-053, IT-054, IT-055, IT-056, IT-057, IT-058, IT-059, IT-060 — malformed data, coverage gaps, partial failure, authorization, concurrent dedup, restart, replay, mount/reload, availability, and large candidates.
- [ ] IT-075, IT-079, IT-089 — persisted evidence reload and availability-driven recommendation/summary changes.
- [ ] IT-115, IT-116, IT-117, IT-118, IT-119 — concurrent/retried credit evaluation, eligibility, and late-result conflict.
- [ ] E2E-002, E2E-006, E2E-011, E2E-012 — governed source-to-case flow, progressive research, full refinement, and usage/credit reconciliation.

## Success Criteria
- Every assigned test case implemented and passing
- Restart, reconnect, retry, and duplicate jobs never duplicate business effects or erase persisted progress.
- The ten-minute deadline always yields the best persisted verified outcome and immutable billing classification.
- Source failure and raw-body retention never remove the evidence required to audit prior recommendations.
