---
status: pending
title: Deliver governed source ingestion and listing evidence
type: backend
complexity: critical
---

# Task 3: Deliver governed source ingestion and listing evidence

## Overview
Build the approved-source catalog, safe retrieval contracts, deterministic reference adapter, normalized listing evidence, availability, and conservative property clustering. This slice establishes fixture-backed ingestion and immutable evidence APIs without depending on later Oban research orchestration or a legally unapproved production source.

<critical>
- ALWAYS READ the PRD, the TechSpec, and their catalogs (`_user_stories.md`, `_tests.md`) before starting
- REFERENCE TECHSPEC for implementation details — do not duplicate here
- FOCUS ON "WHAT" — describe what needs to be accomplished, not how
- MINIMIZE CODE — show code only to illustrate current structure or problem areas
- TESTS REQUIRED — implement every test case assigned in ## Tests
</critical>

<requirements>
- Source activation MUST require approved HTTPS identity, permitted method, current terms/robots reviews, configured limits, registered adapter, and at least one supported pilot city.
- Adapter selection MUST use a compiled registry key; administrators MUST NOT submit module names or enable browser/LLM extraction.
- Source HTTP contracts MUST enforce HTTPS, DNS/IP safety, approved hosts and redirects, timeouts, response limits, rate limits, and explicit failure classes.
- Normalization MUST reject invalid required fields and preserve unknown optional values distinctly from zero.
- Listing snapshots and field evidence MUST be immutable and idempotent; sanitized raw bodies MUST be eligible for deletion after 30 days without removing hashes or evidence.
- Clustering MUST merge only deterministic high-confidence identities and MUST preserve/disclose uncertain possible duplicates.
- Other contexts MUST consume returned listing/property/evidence views through public APIs rather than querying these schemas.
</requirements>

## Subtasks
- [ ] 3.1 Add source, city coverage, compliance, collection, attempt, raw-response, listing, snapshot, evidence, and cluster persistence.
- [ ] 3.2 Implement source lifecycle, optimistic concurrency, activation prerequisites, and adapter registry APIs.
- [ ] 3.3 Implement safe URL, resolver, redirect, bounded HTTP, and durable rate-reservation contracts.
- [ ] 3.4 Implement the adapter behaviour and deterministic sanitized reference adapter fixtures.
- [ ] 3.5 Implement normalization, snapshot upsert, evidence retention, property views, availability, and clustering APIs.
- [ ] 3.6 Deliver administrator source governance UI with stable authorization and stale-state handling.
- [ ] 3.7 Add source, adapter, HTTP, normalization, listing, evidence, and clustering fixtures/tests.

## Implementation Details
Finch is already supervised as `HouseSearch.Finch`; add source-aware safety and test seams around it. Numeric thresholds not fixed by the TechSpec—review staleness, page/response bounds, redirect count, timeouts, and clustering confidence—must be centralized and documented rather than scattered or represented as production-source facts.

### Relevant Files
- `lib/house_search/sources.ex` — source governance public context.
- `lib/house_search/sources/source.ex` — compliance-gated, optimistic-lock source record.
- `lib/house_search/sources/source_city.ex` — unique pilot-city coverage.
- `lib/house_search/sources/adapter_registry.ex` — safe compiled adapter-key mapping.
- `lib/house_search/ingestion.ex` — retrieval/normalization public boundary.
- `lib/house_search/ingestion/adapter.ex` — narrow fetch/normalize behaviour.
- `lib/house_search/ingestion/source_http.ex` — Finch safety and bounded retrieval.
- `lib/house_search/ingestion/safe_url.ex` — protocol, host, redirect, and IP validation.
- `lib/house_search/listings.ex` — snapshot/evidence/property-view public APIs.
- `lib/house_search_web/live/admin/source_live.ex` — governance and source-health UI.
- `test/support/fixtures/sources/` — sanitized fixture-backed adapter payloads.

### Dependent Files
- `lib/house_search/search_cases.ex` — consumes coverage, source outcomes, and current property views.
- `lib/house_search/ranking.ex` — consumes immutable candidate and cluster projections.
- `lib/house_search/ai/evidence_projection.ex` — consumes allowlisted field evidence and safe links.
- `lib/house_search/workers/source_collection_worker.ex` — later runs these contracts durably.
- `lib/house_search/workers/raw_response_retention_worker.ex` — later invokes raw-body expiry APIs.
- `lib/house_search_web/telemetry.ex` — later records source and normalization metrics.

### Related ADRs
- [ADR-001: Broker-Controlled Evidence-Backed Shortlists](adrs/adr-001.md) — requires auditable evidence and disclosed duplicate uncertainty.
- [ADR-002: Confirmed Criteria and Supported Pilot Inventory](adrs/adr-002.md) — constrains supported cities, types, and transactions.
- [ADR-004: Phoenix Modular Monolith with Durable Oban Orchestration](adrs/adr-004.md) — requires public context APIs and later durable workers.
- [ADR-008: Explicit Source Adapters and Bounded Evidence Retention](adrs/adr-008.md) — directly governs this slice.

## Deliverables
- Source governance, compliance, city coverage, adapter registry, and safe HTTP contracts.
- Fixture-backed deterministic adapter with normalized immutable listing evidence.
- Idempotent listing/snapshot persistence, availability transitions, property views, and conservative clustering.
- Administrator source UI and source/listing test fixtures.
- Every test case assigned in `## Tests` implemented and passing **(REQUIRED)**

## Tests

Cases assigned from `_tests.md`, the test contract — read each ID's full definition there before writing tests.

- [ ] UT-011, UT-012, UT-013, UT-014, UT-015, UT-016, UT-017, UT-018 — source lifecycle, compliance, concurrency, rate limits, and URL safety.
- [ ] UT-019, UT-020, UT-021, UT-022, UT-023 — adapter normalization, unknowns, idempotent snapshots, and availability.
- [ ] IT-011, IT-012, IT-014, IT-015, IT-016, IT-017, IT-018 — source validation, authorization, concurrency, rollback, uniqueness, and activation prerequisites.

## Success Criteria
- Every assigned test case implemented and passing
- No unapproved or unsafe source can become active or produce a recommended-safe link.
- Replaying normalized input creates no duplicate snapshot or evidence record.
- Raw-body removal can occur without losing normalized facts, hashes, or provenance.
