---
status: completed
title: Establish invite-only accounts and broker access
type: backend
complexity: high
---

# Task 1: Establish invite-only accounts and broker access

## Overview
Extend the generated Phoenix authentication foundation into an invite-only, account-scoped pilot access system. This slice establishes the actor and authorization contracts every later context and LiveView relies on while preserving generated credential security behavior.

<critical>
- ALWAYS READ the PRD, the TechSpec, and their catalogs (`_user_stories.md`, `_tests.md`) before starting
- REFERENCE TECHSPEC for implementation details — do not duplicate here
- FOCUS ON "WHAT" — describe what needs to be accomplished, not how
- MINIMIZE CODE — show code only to illustrate current structure or problem areas
- TESTS REQUIRED — implement every test case assigned in ## Tests
</critical>

<requirements>
- The system MUST remove public registration while retaining generated login, confirmation, reset-password, settings, token hashing, and credential rules.
- Invitations MUST be single-use, expiring, revocable, hashed at rest, resumable after interruption, and unique for each normalized pending email under concurrent administration.
- Invitation acceptance MUST atomically create or activate the user, account, and membership and confirm the invited identity without duplicate records.
- System administrator role, account membership role, and user suspension status MUST remain distinct authorization dimensions.
- Suspension MUST revoke active sessions, disconnect mounted LiveViews, and be rechecked by every mutating context entry point.
- Foreign-account access MUST use non-disclosing `:not_found` behavior; admin and suspended command failures MUST use stable tagged errors.
- New business records MUST use binary UUID keys and `utc_datetime_usec`; existing generated-auth `utc_datetime` semantics MUST not be silently rewritten.
</requirements>

## Subtasks

- [x] 1.1 Add accounts, memberships, invitations, pilot settings, user roles/status, database constraints, and indexes.
- [x] 1.2 Extend `HouseSearch.Accounts` with invitation, acceptance, capacity, suspension, restoration, actor, and authorization APIs.
- [x] 1.3 Adapt generated session and credential flows for invite-only and suspended-user behavior.
- [x] 1.4 Add active-account and administrator plugs/on-mount hooks with account-scoped actor assigns.
- [x] 1.5 Deliver invitation activation and administrator broker-management LiveViews with search and pagination.
- [x] 1.6 Remove public-registration routes and update all affected navigation and generated tests.
- [x] 1.7 Expand account fixtures and concurrency helpers for administrators, brokers, memberships, invitations, and pilot capacity.


## Implementation Details
Use additive migrations and retain the generated authentication context as the foundation described by the TechSpec. The account is the ownership boundary for later cases and billing; expose public authorization APIs rather than allowing other contexts to query Accounts schemas.

### Relevant Files
- `lib/house_search/accounts.ex` — generated context to extend with account and invitation APIs.
- `lib/house_search/accounts/user.ex` — add system role, status, and suspension fields while preserving credentials.
- `lib/house_search/accounts/user_token.ex` — session revocation and existing hashed-token conventions.
- `lib/house_search/accounts/user_notifier.ex` — recoverable invitation delivery through Swoosh.
- `lib/house_search_web/user_auth.ex` — actor construction, admin/active membership hooks, and LiveView disconnects.
- `lib/house_search_web/router.ex` — remove registration and add invitation, broker, and admin routes.
- `lib/house_search_web/controllers/user_session_controller.ex` — reject suspended login attempts.
- `lib/house_search_web/live/user_login_live.ex` — remove public sign-up affordances.
- `priv/repo/migrations/20260715134508_create_users_auth_tables.exs` — existing UUID/auth timestamp baseline.
- `test/support/fixtures/accounts_fixtures.ex` — account-aware actor and lifecycle fixtures.

### Dependent Files
- `lib/house_search/usage.ex` — will consume account ownership and active-actor contracts.
- `lib/house_search/search_cases.ex` — will enforce membership and suspension for every case command.
- `lib/house_search_web/live/admin/usage_live.ex` — will depend on the administrator hook.
- `lib/house_search_web/live/admin/source_live.ex` — will depend on the administrator hook.
- `test/support/conn_case.ex` — must provide broker/admin login helpers with account actors.

### Related ADRs
- [ADR-003: Invite-Only Pilot and Transparent Usage Charging](adrs/adr-003.md) — defines controlled pilot access and trial lifecycle.
- [ADR-004: Phoenix Modular Monolith with Durable Oban Orchestration](adrs/adr-004.md) — requires public context boundaries.
- [ADR-005: Generated Authentication with Account Memberships and Invitations](adrs/adr-005.md) — directly governs this slice.

## Deliverables
- Invite-only account, membership, invitation, capacity, role, and suspension persistence with concurrency-safe constraints.
- Account-scoped authorization and active-session invalidation integrated into generated authentication.
- Invitation activation and administrator broker-management LiveViews with stable pagination.
- Updated fixtures and generated-auth regression coverage with public registration removed.
- Every test case assigned in `## Tests` implemented and passing **(REQUIRED)**

## Tests

Cases assigned from `_tests.md`, the test contract — read each ID's full definition there before writing tests.

- [x] UT-001, UT-002, UT-003, UT-004, UT-005, UT-006, UT-007, UT-008, UT-009, UT-010 — invitation validation/lifecycle, pilot capacity, roles, membership authorization, and suspension.
- [x] IT-001, IT-002, IT-003, IT-004, IT-005, IT-006, IT-007, IT-008, IT-009, IT-010 — complete admin and broker access behavior, concurrency, replay, identity safety, and pagination.
- [ ] 
## Success Criteria
- Every assigned test case implemented and passing
- Public registration is unavailable while generated credential flows remain covered.
- Concurrent invitations and suspension/session races produce one auditable outcome.
- Later contexts can authorize an explicit `%{user_id, account_id}` actor without querying Accounts tables.
