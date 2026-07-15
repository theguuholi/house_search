# Technical Specification: HouseSearch MVP

## Executive Summary

HouseSearch will be a Phoenix modular monolith backed by PostgreSQL, Oban OSS,
Phoenix PubSub, and LiveView. PostgreSQL is the source of truth for user access,
source policy, listing evidence, case versions, ranking snapshots, shortlist
decisions, generated summaries, and the immutable usage ledger. Oban executes
durable source refresh, normalization, recomputation, deadline, credit, and
retention work. PubSub only invalidates LiveView state; reconnecting always
rebuilds the screen from persisted records.

The design extends the repository's generated email/password authentication
with administrator invitations, accounts, memberships, and suspension. Source
retrieval uses explicit approved adapters. Eligibility, deduplication, ranking,
billing, and evidence projection remain deterministic Elixir. A provider-neutral
Sagents boundary handles conversational interpretation and optional narrative,
with deterministic factual output as the failure fallback. This design covers
the complete `_prd.md` and all journeys in `_user_stories.md`.

## System Architecture

### Component Overview

| Component | Responsibility | Permitted dependencies |
| --- | --- | --- |
| `HouseSearch.Accounts` | Generated authentication, invitations, users, accounts, memberships, roles, suspension, pilot capacity | Ecto, Mailer |
| `HouseSearch.Sources` | Source identity, compliance review, city coverage, permitted adapter, health, limits, optimistic concurrency | Ecto |
| `HouseSearch.Ingestion` | Approved adapter contract, safe HTTP retrieval, collection runs, normalization, snapshot persistence | `Sources`, `Listings`, Finch |
| `HouseSearch.Listings` | Normalized listings, immutable verification snapshots, evidence, availability, property clustering | Ecto |
| `HouseSearch.SearchCases` | Drafts, messages, clarifications, confirmed criteria versions, research runs, matches, shortlist versions, feedback, summaries | `Accounts`, `Listings`, `Ranking`, `Usage`, `AI` |
| `HouseSearch.Ranking` | Pure validation, eligibility, near-match failures, dedup decisions, `v1` score and stable ordering | Immutable structs only |
| `HouseSearch.AI` | Sagents orchestration, provider behaviour, schema validation, prompt/model audit, factual narrative projection | Sagents, configured provider |
| `HouseSearch.Usage` | Plans, billing periods, authorization quotes, overage acceptances, immutable ledger events, credits and balances | Ecto |
| `HouseSearch.Workers` | Durable orchestration through public context APIs | Oban and public context APIs |
| `HouseSearchWeb` | Broker and administrator LiveViews, auth hooks, account scoping, progressive state and copy-ready output | Public context APIs |

Contexts own their tables and expose business operations. A context may consume
another context's returned structs or services but must not import its schemas
to construct cross-context queries. Multi-context atomic operations use a
public function that returns an `Ecto.Multi`; the coordinating context composes
and executes the transaction.

### End-to-End Data Flow

1. An administrator creates an invitation. Acceptance uses the generated auth
   credential rules and creates the broker's account and membership.
2. The broker sends an idempotent draft message. `AI.interpret/2` returns either
   validated proposed criteria or one clarification. The persisted draft
   version remains non-billable.
3. `SearchCases.quote_opening/2` validates criteria and obtains a locked usage
   quote. The broker sees included, overage, or blocked status before opening.
4. `SearchCases.open_case/2` atomically creates the case, criteria version,
   research run, usage event, and Oban orchestration job. A client-generated
   idempotency key prevents duplicate openings.
5. The research run immediately queries verified local snapshots, persists
   match and shortlist snapshots, then enqueues refreshes for stale active
   sources covering the confirmed cities.
6. Each source attempt retrieves bounded pages, normalizes records, persists
   immutable evidence, and schedules recomputation. Source failures remain
   isolated and visible.
7. Recomputations persist a new match snapshot for the same criteria and data
   watermark. PubSub broadcasts `{case_id, research_run_id}`; the LiveView
   reloads current persisted state.
8. A deadline worker finalizes the run by ten minutes. Completion classification
   uses persisted source outcomes and verified-property count. A failed
   zero-result run schedules exactly-once credit evaluation.
9. Broker near-match approvals, feedback, and shortlist readiness create new
   shortlist versions under optimistic locking. Generated summaries snapshot
   only the current approved, available entries.
10. In-window refinement creates a new criteria version and research run without
    a usage event. The original terminal result remains immutable; expiry is a
    computed refinement condition, not an overwrite of result status.

### Story-to-Component Mapping

| Story | Primary components | Technical realization |
| --- | --- | --- |
| US-001 | Accounts, Web | Generated auth plus admin invitations, memberships, suspension and session revocation |
| US-002 | Sources, Ingestion, Web | Compliance-gated sources, adapter registry, health and city-scoped collection |
| US-003 | SearchCases, AI, Web | Persisted drafts/messages, idempotent interpretation, one unresolved clarification |
| US-004 | SearchCases, Ranking | Validated classified criteria and immutable optimistic-lock versions |
| US-005 | Usage, SearchCases | Locked quote plus transactional case, usage event, consent and idempotency |
| US-006 | Workers, Ingestion, Listings, SearchCases, Web | Local-first recomputation, durable refreshes, source outcomes, deadline and reload broadcasts |
| US-007 | Ranking, SearchCases | Exact and near-match sets, failed-requirement projection, approval versioning |
| US-008 | Listings, Ranking, AI, Web | Field evidence, deterministic reasons, safe links, bounded narrative |
| US-009 | SearchCases, Web | Ready-shortlist gate and immutable copy-ready summary snapshots |
| US-010 | SearchCases, Ranking | Validated feedback, exclusion set and exact-first replacement transaction |
| US-011 | SearchCases, Usage | Seven-day eligibility, new criteria/research/shortlist versions, no second usage event |
| US-012 | Usage, Workers, Web | Immutable ledger, locked balances, terminal failure credit and reconciliation views |

## Implementation Design

### Core Interfaces

The primary boundary used by the LiveViews and workers is the `SearchCases`
context. It accepts authenticated actor and idempotency information explicitly.

```elixir
@type actor :: %{user_id: Ecto.UUID.t(), account_id: Ecto.UUID.t()}
@type command_error ::
  :unauthorized | :suspended | :stale | :expired | :invalid_state |
  :usage_blocked | :overage_required | Ecto.Changeset.t()

@spec open_case(actor(), Ecto.UUID.t(), String.t(), map()) ::
  {:ok, SearchCase.t()} | {:error, command_error()}
@spec refine_case(actor(), Ecto.UUID.t(), String.t(), map()) ::
  {:ok, CriteriaVersion.t()} | {:error, command_error()}
@spec get_case_view(actor(), Ecto.UUID.t()) ::
  {:ok, CaseView.t()} | {:error, :not_found}
```

Usage exposes a quote/commit contract. The opaque quote version must still be
current when case opening obtains the account and billing-period locks.

```elixir
@type quote :: %{
  kind: :included | :overage | :blocked,
  amount_cents: non_neg_integer(),
  version: String.t(),
  reason: atom() | nil
}

@spec quote_case(Ecto.UUID.t(), DateTime.t()) :: {:ok, quote()}
@spec consume_multi(Ecto.Multi.t(), map()) :: Ecto.Multi.t()
@spec credit_failed_case(Ecto.UUID.t(), String.t()) ::
  {:ok, UsageEvent.t()} | {:error, :ineligible | :not_terminal}
```

All collection adapters implement a narrow retrieval contract. Adapter keys
come from an application registry; administrators cannot submit module names.

```elixir
@callback fetch_page(Source.t(), City.t(), cursor :: map() | nil) ::
  {:ok, %{items: [RawListing.t()], next_cursor: map() | nil,
          response_meta: map()}}
  | {:error, Failure.t()}

@callback normalize(RawListing.t(), Source.t()) ::
  {:ok, NormalizedListing.t()} | {:error, NormalizationError.t()}
```

The AI boundary accepts only versioned schemas and returns no domain side
effects. Application contexts decide whether to persist and act on a response.

```elixir
@callback complete(operation :: :interpret | :explain, map(), keyword()) ::
  {:ok, %{payload: map(), provider_meta: map()}}
  | {:error, ProviderError.t()}

@spec interpret(DraftView.t(), keyword()) ::
  {:ok, ProposedCriteria.t() | Clarification.t()} | {:error, AIError.t()}
@spec explain(EvidenceProjection.t(), keyword()) ::
  {:ok, Narrative.t()} | {:error, AIError.t()}
```

`Ranking.evaluate/3` is pure. It returns exact and near matches with explicit
facts; no function reads the database or calls AI.

```elixir
@spec evaluate(Criteria.t(), [Property.t()], version: :v1) :: %{
  exact: [RankedMatch.t()],
  near: [RankedMatch.t()],
  rejected: [RejectedCandidate.t()]
}

@spec score(Criteria.t(), Property.t(), version: :v1) ::
  {:ok, Score.t()} | {:error, :ineligible | :insufficient_evidence}
```

### Data Models

All primary and foreign keys are binary UUIDs. Business timestamps use
`utc_datetime_usec`; expiry and ordering never rely on local time. Money uses
integer BRL cents, area uses `Decimal`, and external input maps are normalized
before changesets. Mutable administrator records include `lock_version`.

#### Accounts

| Schema | Essential fields and constraints |
| --- | --- |
| `users` | Existing email, password hash, confirmation; add `system_role` (`admin`/`member`), `status` (`active`/`suspended`), `suspended_at`; unique normalized email |
| `accounts` | `name`, `status`, `timezone`, `pilot_started_at`; one broker account per accepted pilot invitation |
| `memberships` | `account_id`, `user_id`, `role`; unique account/user pair |
| `invitations` | hashed token, invited email/name, inviter, status, expiry, accepted user/account; one pending invitation per email |
| `pilot_settings` | singleton participant limit and `lock_version` |

Public registration routes are removed. Invitation tokens are single-use,
hashed at rest, expire after a configured duration, and are invalidated on
revocation or acceptance. Suspension deletes session tokens and is also checked
by context functions to cover already-mounted LiveViews.

#### Sources and Ingestion

| Schema | Essential fields and constraints |
| --- | --- |
| `sources` | name, kind, HTTPS base URL, adapter key, permitted method, status, refresh interval, request limit, allowed hosts, compliance reviewer/dates, `lock_version` |
| `source_cities` | source, canonical city enum, enabled; unique source/city |
| `collection_runs` | source, trigger, status, cursor, counts, start/end, failure class/code, cost; optional case/run attribution |
| `source_attempts` | research run, source/city, collection run, status, timestamps, error code; unique research run/source/city |
| `raw_responses` | collection run, response hash, status, headers allowlist, sanitized body, body expiry at 30 days |

Activation requires a supported method, at least one pilot city, current terms
and robots reviews, limits, and an adapter registered for that method. A
degraded source contributes existing verified snapshots but receives no new
on-demand requests until an administrator reactivates it. Deactivation stops
new retrieval without deleting evidence.

#### Listings and Evidence

| Schema | Essential fields and constraints |
| --- | --- |
| `listings` | source, external ID, canonical HTTPS URL, current snapshot, status; unique source/external ID and source/canonical URL fallback |
| `listing_snapshots` | listing, collection run, data hash, normalized property fields, captured/verified timestamps; unique listing/data hash |
| `field_evidence` | snapshot, field name, normalized value, source locator/path, excerpt hash; unique snapshot/field |
| `property_clusters` | cluster status, deterministic dedup key, confidence version |
| `property_cluster_members` | cluster, listing, confidence, decision kind; unique listing membership |

Required normalized property fields are transaction, property type, price,
city, neighborhood/location text, canonical link, and availability. Optional
numeric fields are nullable and preserve unknown distinctly from zero. A
property view selects the freshest valid snapshot and retains alternate source
provenance.

Deduplication first collapses source/external-ID identity, then exact normalized
keys. A conservative deterministic similarity rule may merge only above the
versioned high-confidence threshold. Borderline pairs remain separate and are
marked `possible_duplicate`; no LLM makes cluster decisions.

#### Intake, Research, and Shortlists

| Schema | Essential fields and constraints |
| --- | --- |
| `request_drafts` | account, creator, status, current version, `lock_version` |
| `draft_messages` | draft, client message ID, sequence, role, body; unique draft/client ID and draft/sequence |
| `draft_interpretations` | draft version, schema/prompt/provider/model versions, proposed criteria or clarification, status |
| `search_cases` | account, creator, original confirmation, refinement expiry, current criteria version; never stores buyer identity |
| `criteria_versions` | case, version, normalized classified criteria JSONB, confirmer, confirmed at; unique case/version |
| `research_runs` | case, criteria version, state (`searching`/terminal), deadline, data watermark, completion reason; unique case/criteria version |
| `match_snapshots` | run, cluster, eligibility, failed requirements, score and breakdown, ranking version, evidence watermark |
| `shortlist_versions` | run, version, reason, readiness, creator, `lock_version`; unique run/version |
| `shortlist_entries` | shortlist version, cluster, rank, kind, approval state, compromises, source snapshot; at most three active entries |
| `near_match_approvals` | run, cluster, failed requirements hash, approver, idempotency key |
| `recommendation_feedback` | run, cluster, verdict, reason, bounded note, actor, current flag, idempotency key |
| `summary_snapshots` | shortlist version, generated at, deterministic body, optional narrative status, stale flag |

Criteria JSONB uses a versioned schema whose entries contain `kind`, operator,
normalized value, and classification. Database checks enforce supported kinds;
`Ranking.Criteria` performs cross-field validation. Confirmation uses the draft
lock version so a stale tab cannot confirm old values.

Research result state is `complete`, `partial`, `empty`, or `failed` and remains
immutable after finalization. `expired` is computed from
`refinement_expires_at`; it never erases the terminal outcome. A new refinement
creates new criteria, research, match, and shortlist versions.

#### Usage

| Schema | Essential fields and constraints |
| --- | --- |
| `subscriptions` | account, plan, status, start/end, included units; one active period per account |
| `billing_periods` | account, plan snapshot, included allowance, start/end, status, `lock_version` |
| `usage_authorizations` | account, criteria fingerprint, quote kind/version, amount, accepted at, idempotency key |
| `usage_events` | account, case, billing period, kind (`consume_included`, `accept_overage`, `credit`), units, cents, idempotency key, causation event |

The ledger is append-only. Balances are sums of events within the applicable
period, never mutable counters. Case opening locks the active billing period,
recomputes the quote, validates overage consent if required, and inserts exactly
one consumption event in the same transaction as the case. A unique business
idempotency key covers retries. Credits reference the consumption event and
have a unique credited-case constraint.

### Browser Routes and Event Surface

The MVP exposes no public JSON API. LiveView events call context functions and
receive tagged tuples. Routes use verified routes and authenticated
`live_session` hooks.

| Method/route | Surface | Authorization and behavior |
| --- | --- | --- |
| `GET /invitations/:token` | `InvitationLive` | Valid matching identity accepts invite and establishes password; invalid state is generic |
| `GET /users/log_in` and generated credential routes | Existing auth | Retained generated password, reset, settings, confirmation flows |
| `GET /broker` | `BrokerDashboardLive` | Active membership; allowance and recent cases |
| `GET /requests/new` | `RequestLive` | Active broker; draft/intake/confirmation/usage quote |
| `GET /cases/:id` | `CaseLive` | Owning account or administrator; persisted progress and shortlist actions |
| `GET /cases/:id/refine` | `RefinementLive` | Owning active broker and in-window case |
| `GET /admin/brokers` | `Admin.BrokerLive` | Administrator invitations, plan and suspension actions |
| `GET /admin/sources` | `Admin.SourceLive` | Administrator source compliance and health actions |
| `GET /admin/usage` | `Admin.UsageLive` | Administrator account/case/ledger reconciliation |

Every mutating LiveView event includes a client idempotency key and expected
resource version. Errors map to stable user-visible categories:
`unauthorized`, `suspended`, `stale`, `invalid`, `expired`, `usage_changed`,
`overage_required`, `temporarily_unavailable`, and `not_found`. Authorization
failures use `not_found` when existence would leak another account's data.

### State and Concurrency Rules

- Only one unresolved clarification may exist for a draft. A new message either
  resolves it or creates the next interpretation version.
- Case opening, overage acceptance, near-match approval, feedback, refinement,
  and summary generation require idempotency keys.
- Expected lock versions reject stale administrator edits, confirmations,
  approvals, and shortlist mutations with `:stale`.
- The shortlist mutation transaction locks the current shortlist version,
  rejects stale action targets, excludes all rejected clusters, selects the next
  exact match, and only proposes a near match when no exact candidate remains.
- An already-approved near match is never silently displaced. New exact results
  are presented as an explicit replacement opportunity.
- Listing unavailability creates a new shortlist version automatically; it may
  fill with an exact match but never auto-admit a near match.
- Deadline finalization locks the research run. Subsequent late collection may
  update the local index but cannot rewrite the terminal run or its billing
  classification.

## Integration Points

### Sagents and Configured AI Provider

`HouseSearch.AI.Provider` is configured at runtime with a provider adapter,
model, timeout, and credentials. Only JSON-schema structured outputs are
accepted. Interpretation input includes the bounded conversation and supported
criterion vocabulary. Explanation input contains only the evidence projection
for current shortlisted properties. Transient provider errors receive bounded
Oban retries; explanation failure never blocks deterministic results. Prompts,
schema versions, model identity, usage, latency, and error category are logged
and persisted without buyer identity.

### Approved Listing Sources

Each approved source selects a compiled adapter key. `SourceHTTP` uses Finch
with HTTPS-only URLs, DNS/IP checks, approved-host and redirect validation,
connect/receive timeouts, a response-size ceiling, per-source concurrency, and
rate limiting. Adapters return explicit transient, permanent, rate-limited, or
invalid-data failures. Retries honor source limits and never convert an error
into success. Production source selection is a deployment dependency outside
this TechSpec until a legal/compliance record exists.

### Email

Swoosh sends invitation, confirmation, and password-reset messages. Delivery
failure leaves an invitation recoverable and resendable; it does not create a
second invitation or account. Production requires a configured Swoosh adapter
and sender domain. Tests use `Swoosh.Adapters.Test`.

## Impact Analysis

| Component | Impact Type | Description and Risk | Required Action |
| --- | --- | --- | --- |
| Generated Accounts/auth | Modified | Public registration conflicts with invite-only PRD; suspension must revoke sessions | Preserve generated credential behavior, add roles/status/invitations, remove registration route |
| Router | Modified | New broker/admin LiveView scopes and authorization hooks | Add verified routes and admin/active-membership hooks |
| Domain contexts | New | Greenfield implementation with cross-context consistency risk | Add contexts and public APIs in dependency order |
| Database | New | Large audit/version model and concurrency constraints | Add migrations, checks, unique indexes, locks and query indexes |
| Oban/Application | New/modified | Durable work and deadlines; queue contention risk | Add Oban dependency, repo migration, supervision and bounded queues |
| Finch/source HTTP | Modified/new | SSRF, redirects, rate and payload risk | Add approved-host client and adapter registry |
| Sagents/AI provider | New | Volatile external schema and hallucination risk | Add provider behaviour, schema validation, fake and audit records |
| LiveViews | New | Progressive state, reconnect and stale-tab behavior | Render persisted projections and use PubSub invalidations |
| Existing tests/support | Modified | No domain fixtures or LiveView case support exists | Add account/source/listing/case fixtures and Oban/AI/source test modes |
| Telemetry | Modified | Business metrics need stable low-cardinality events | Add event definitions and structured metadata filtering |

## Testing Approach

`_tests.md` is the canonical concrete case catalog. ExUnit, Phoenix.LiveViewTest,
Ecto SQL Sandbox, Oban testing modes, StreamData, Swoosh test adapter, bypassed
Finch endpoints, sanitized adapter fixtures, and a deterministic AI fake form
the harness. Fakes sit only at external I/O boundaries; integration tests use
real contexts, PostgreSQL constraints, Oban workers, PubSub, and LiveViews.

Unit tests cover criteria validation, URL safety, normalization, eligibility,
deduplication, ranking, evidence projection, state transitions, usage math, and
every tagged error. Property tests cover score bounds, stable ordering,
idempotent upsert, and ledger invariants. Integration tests cover every context
boundary, transaction, worker retry/finalization, authorization rule, and
concurrency race. End-to-end LiveView tests cover every broker and administrator
journey. Default tests never contact live AI or property sources; deployment
smoke tests remain separately tagged and manual.

Performance fixtures use 100 times the five-broker pilot norm: 500 broker
accounts, 5,000 historical cases, 300,000 active listing snapshots, 10,000
prefilter candidates for one case, and 100 concurrent source batches. The
search view must paginate candidates, load current state without scanning raw
evidence bodies, and keep deterministic recomputation within the ten-minute
business deadline. These are verification workloads, not promised production
throughput SLAs.

## Development Sequencing

### Build Order

1. Extend generated auth with accounts, memberships, invitations, roles,
   suspension, authorization hooks, and account fixtures.
2. Implement subscriptions, billing periods, quote calculation, append-only
   usage ledger, and idempotent `Ecto.Multi` composition.
3. Implement source governance, city enums, compliance gates, adapter registry,
   and safe HTTP client.
4. Implement listings, snapshots, field evidence, availability, retention, and
   conservative clustering.
5. Implement request drafts, messages, criteria schema/validation, cases,
   research runs, and version projections without AI.
6. Implement pure ranking `v1`, match snapshots, shortlist versioning,
   near-match approval, feedback, replacement, and summaries.
7. Add Oban queues and workers for ingestion, normalization, recomputation,
   deadlines, credits, expiry views, and raw-response retention.
8. Add provider-neutral Sagents interpretation and narrative with validation
   and deterministic fallbacks.
9. Add broker LiveViews and PubSub reload flow, then administrator LiveViews.
10. Run full contract, integration, LiveView, security, performance, and
    observability verification with at least one legally approved source adapter.

### Technical Dependencies

- Add Oban OSS, Sagents, StreamData, and any provider adapter selected at
  deployment. Finch remains the HTTP client.
- Select and approve at least one named source before production ingestion; the
  source must have a stable contract or sanitized fixture set.
- Configure a production Swoosh adapter and sender identity for invitations.
- Configure the AI provider/model and secrets before enabling conversational AI;
  deterministic criteria editing and factual reasons must remain operable when disabled.
- Decide operational retention for case history and normalized evidence before
  commercial launch; only raw-response retention is fixed at 30 days here.

## Monitoring and Observability

Emit Telemetry events for invitation lifecycle, login/suspension denial, usage
quote and consumption, source attempt, normalization result, listing freshness,
research recomputation/finalization, shortlist mutation, AI call, summary
generation, and credit evaluation. Logs include `request_id`, `account_id`,
`case_id`, `criteria_version`, `research_run_id`, `source_id`, `collection_run_id`,
`job_id`, `ranking_version`, and idempotency-key hash where applicable. They
exclude tokens, credentials, raw prompts, buyer text, response bodies, and
feedback notes.

Track source success/error/rate-limit counts, collection latency and freshness,
invalid-record ratio, queue age, job retries, time to first verified result,
time to three exact matches, terminal-state distribution, AI error/latency/cost,
usefulness by ranking version, duplicate-removal rate, usage/credit invariants,
and stale-summary attempts. Alert when an active source has five consecutive
failures, any research deadline job is more than one minute late, the oldest
on-demand queue job exceeds two minutes, a ledger invariant fails, a case has
multiple consumption/credit effects, or raw-response deletion is more than 24
hours behind.

## Technical Considerations

### Key Decisions

- **Modular monolith with Oban**: maximizes durability without distributed-system
  overhead; trades independent scaling for simpler operations.
- **Generated auth plus memberships**: reuses secure credential flows and makes
  the account the billing boundary; adds authorization joins.
- **Immutable versions and ledger events**: make retries, concurrency, and audit
  explicit; increase schema count and storage.
- **Deterministic ranking `v1`**: allocates 55/15/15/15 points to preferences,
  freshness, completeness, and source confidence; trades live tuning for replay.
- **Provider-neutral Sagents**: keeps AI at language boundaries; requires schema
  validation and a common provider contract.
- **Explicit adapters and 30-day raw retention**: protect authorization and
  minimize third-party content; require code per source and limit late replay.

### Known Risks

- **Source legality and stability — high**: no production source is approved.
  Block activation without compliance records and do not promise a named source
  in implementation tasks until approval exists.
- **State-model breadth — medium**: twelve stories create many audit records.
  Build projections behind context APIs and test transitions rather than
  exposing schemas directly to LiveViews.
- **Billing concurrency — high**: use database locks, append-only events, unique
  causation constraints, and property tests for exactly-once balance effects.
- **AI factual leakage — medium**: project an allowlisted evidence payload,
  validate output references, and fall back to deterministic reasons.
- **Duplicate uncertainty — medium**: merge conservatively and disclose possible
  duplicates. Never use narrative output as a clustering signal.
- **Long-running ingestion pressure — medium**: bound pages and payloads,
  partition queues, index current projections, and observe queue age.
- **Generated auth drift — low**: retain existing generator tests while adding
  invitation-only route and suspension tests.

## Architecture Decision Records

- [ADR-001: Broker-Controlled Evidence-Backed Shortlists](adrs/adr-001.md) — Exact matches lead and near-matches require explicit compromise approval.
- [ADR-002: Confirmed Criteria and Supported Pilot Inventory](adrs/adr-002.md) — Brokers confirm every criterion classification within the fixed pilot boundary.
- [ADR-003: Invite-Only Pilot and Transparent Usage Charging](adrs/adr-003.md) — Cases consume transparent units with seven-day refinement and failure credits.
- [ADR-004: Phoenix Modular Monolith with Durable Oban Orchestration](adrs/adr-004.md) — One deployment uses PostgreSQL and Oban for durable progressive research.
- [ADR-005: Generated Authentication with Account Memberships and Invitations](adrs/adr-005.md) — Existing auth is adapted to invitation-only account-scoped access.
- [ADR-006: Provider-Neutral Sagents Boundary](adrs/adr-006.md) — AI remains a configured, validated language-edge integration.
- [ADR-007: Versioned Deterministic Ranking Formula](adrs/adr-007.md) — Ranking `v1` is fixed, explainable, and reproducible.
- [ADR-008: Explicit Source Adapters and Bounded Evidence Retention](adrs/adr-008.md) — Approved source adapters preserve evidence while raw responses expire after 30 days.
