---
status: pending
title: Add provider-neutral conversational AI
type: backend
complexity: high
---

# Task 6: Add provider-neutral conversational AI

## Overview
Add the constrained Sagents/provider boundary for conversational interpretation and optional recommendation narrative. Application contexts retain all state changes and deterministic decisions; provider failure removes only language enhancement, never criteria editing, factual reasoning, ranking, or shortlist control.

<critical>
- ALWAYS READ the PRD, the TechSpec, and their catalogs (`_user_stories.md`, `_tests.md`) before starting
- REFERENCE TECHSPEC for implementation details — do not duplicate here
- FOCUS ON "WHAT" — describe what needs to be accomplished, not how
- MINIMIZE CODE — show code only to illustrate current structure or problem areas
- TESTS REQUIRED — implement every test case assigned in ## Tests
</critical>

<requirements>
- `HouseSearch.AI.Provider` MUST expose only the documented interpret/explain structured-output operations and MUST hide provider-specific types.
- Tests MUST use a deterministic fake and MUST never call a live provider.
- Interpretation MUST return validated supported criteria or exactly one clarification and MUST reject invented criteria, hostile output, and subjective/protected-neighborhood claims.
- Explanation input MUST contain only bounded current verified evidence with identifiers, provenance, unknowns, compromises, and safe links.
- Every generated factual claim MUST reference evidence present in the supplied projection or be rejected.
- Provider timeout, malformed output, disabled configuration, or unavailable model MUST preserve deterministic reasons and return stable narrative-unavailable state.
- AI audit/telemetry MUST persist provider/model/schema/prompt/request/usage/latency/status metadata while excluding buyer identity, raw prompts, credentials, and response bodies.
</requirements>

## Subtasks
- [ ] 6.1 Add the provider behaviour, typed errors, runtime configuration, and disabled/unconfigured mode.
- [ ] 6.2 Add the Sagents adapter without exposing provider types to domain contexts.
- [ ] 6.3 Implement versioned interpretation validation and one-clarification enforcement.
- [ ] 6.4 Implement bounded evidence projection and narrative evidence-reference validation.
- [ ] 6.5 Persist privacy-safe AI call/narrative audit state and current-watermark identity.
- [ ] 6.6 Integrate interpretation with persisted drafts and optional narrative with current recommendations.
- [ ] 6.7 Add deterministic fake responses for valid, hostile, malformed, timeout, and unavailable outcomes.
- [ ] 6.8 Add privacy-safe telemetry and complete conversational/evidence LiveView tests.

## Implementation Details
No production provider/model or pinned Sagents package contract is selected; preserve runtime configuration and disabled fallback rather than inventing a deployment choice. Coordinate current-narrative persistence with Task 05, and centralize unspecified conversation/evidence/narrative bounds.

### Relevant Files
- `lib/house_search/ai.ex` — public interpret, explain, and validation boundary.
- `lib/house_search/ai/provider.ex` — provider-neutral callback contract.
- `lib/house_search/ai/providers/sagents.ex` — configured Sagents adapter.
- `lib/house_search/ai/evidence_projection.ex` — bounded allowlisted evidence payload.
- `lib/house_search/ai/response_validator.ex` — schema, vocabulary, clarification, and evidence checks.
- `lib/house_search/ai/call.ex` — privacy-safe call audit record.
- `test/support/fakes/ai_provider.ex` — deterministic offline provider fake.
- `config/runtime.exs` — runtime provider/model/timeout/secrets configuration.
- `config/test.exs` — deterministic fake provider selection.
- `lib/house_search_web/telemetry.ex` — low-cardinality AI metrics.

### Dependent Files
- `lib/house_search/search_cases/draft_interpretation.ex` — stores validated proposals/clarifications and audit references.
- `lib/house_search/ranking/criteria.ex` — supplies the allowed criterion vocabulary.
- `lib/house_search/search_cases/summary_snapshot.ex` — stores optional narrative status without replacing factual content.
- `lib/house_search_web/live/request_live.ex` — renders one-at-a-time clarification and persisted conversation.
- `lib/house_search_web/live/case_live.ex` — renders narrative/fallback alongside evidence.
- `lib/house_search/workers/` — later uses typed retryability for durable AI attempts.

### Related ADRs
- [ADR-001: Broker-Controlled Evidence-Backed Shortlists](adrs/adr-001.md) — broker control and evidence remain authoritative.
- [ADR-002: Confirmed Criteria and Supported Pilot Inventory](adrs/adr-002.md) — constrains interpretation vocabulary and subjective language.
- [ADR-004: Phoenix Modular Monolith with Durable Oban Orchestration](adrs/adr-004.md) — application contexts persist and workers later retry.
- [ADR-006: Provider-Neutral Sagents Boundary](adrs/adr-006.md) — directly governs this slice.
- [ADR-007: Versioned Deterministic Ranking Formula](adrs/adr-007.md) — AI must not alter ranking.
- [ADR-008: Explicit Source Adapters and Bounded Evidence Retention](adrs/adr-008.md) — narrative uses normalized evidence, never raw responses.

## Deliverables
- Provider-neutral AI behavior, Sagents adapter, runtime configuration, and deterministic fake.
- Validated conversational interpretation and one-objective-clarification flow.
- Bounded evidence projection, narrative reference validation, and deterministic fallback.
- Privacy-safe call/narrative audit and telemetry integrated with broker LiveViews.
- Every test case assigned in `## Tests` implemented and passing **(REQUIRED)**

## Tests

Cases assigned from `_tests.md`, the test contract — read each ID's full definition there before writing tests.

- [ ] UT-048, UT-049, UT-050, UT-051, UT-052 — interpretation rejection, evidence projection/bounds, claim validation, and fallback.
- [ ] IT-021, IT-029, IT-030, IT-076, IT-077 — safe interpretation, supported/unsupported inventory, large proposals, narrative timeout, and regeneration.
- [ ] E2E-003, E2E-008 — conversational intake/reconnect and evidence-bounded narrative/fallback journeys.

## Success Criteria
- Every assigned test case implemented and passing
- Default tests and disabled production configuration perform no external AI request.
- Invalid or unsupported provider output cannot mutate confirmed domain state or add a factual claim.
- Provider failure leaves deterministic criteria editing, evidence, reasons, and shortlist controls usable.

