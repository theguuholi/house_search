# Test Specification: HouseSearch MVP

Canonical test contract for HouseSearch MVP. Companion to `_techspec.md`.
Derived from `_user_stories.md` for behavior and `_techspec.md` for components.

## Strategy

- **Frameworks and harnesses:** ExUnit, Phoenix.LiveViewTest, Ecto SQL Sandbox,
  Oban inline/manual test modes, Swoosh test adapter, StreamData, a local Finch
  test endpoint, sanitized source fixtures, and a deterministic
  `HouseSearch.AI.Provider` fake. External I/O is the only fake boundary.
- **Execution:** unit and integration cases run under `mix test`; LiveView E2E
  cases run in the same suite with SQL Sandbox and manual Oban draining.
  Separately tagged deployment smoke tests may contact an approved source or AI
  provider and never run in default local or CI suites.
- **Conventions:** test names begin with the stable ID below. Unit cases use the
  stated class. Database concurrency cases use separate sandbox owners and
  `Task` barriers. Times use an injected clock. UUIDs, idempotency keys, prompt
  versions, and fixture hashes are explicit. Assertions target persisted state,
  tagged errors, rendered LiveView text, job counts, or emitted events.
- **Performance fixtures:** the large-data cases use 500 accounts, 5,000 cases,
  300,000 active snapshots, 10,000 prefilter candidates, and 100 bounded source
  batches. They assert pagination, bounded queries, stable ordering, and
  completion inside the ten-minute business deadline rather than a
  machine-specific millisecond SLA.

## Coverage Matrix

### User Stories and Edge Cases

| Source | Behavior | Unit | Integration | E2E |
| --- | --- | --- | --- | --- |
| US-001 | Invite and control pilot brokers | UT-001–UT-010 | IT-001–IT-010 | E2E-001 |
| US-001.EC-1 | Malformed invitation email | UT-001 | IT-001 | — |
| US-001.EC-2 | Missing broker name or email | UT-002 | IT-002 | — |
| US-001.EC-3 | Pilot participant limit | UT-003 | IT-003 | — |
| US-001.EC-4 | Non-admin access management | UT-009 | IT-004 | — |
| US-001.EC-5 | Concurrent duplicate invitations | — | IT-005 | — |
| US-001.EC-6 | Interrupted activation resumes | — | IT-006 | — |
| US-001.EC-7 | Accepted invitation replay | UT-005 | IT-007 | — |
| US-001.EC-8 | Activation while signed in as another user | UT-009 | IT-008 | — |
| US-001.EC-9 | Expired, revoked, or accepted invitation | UT-004–UT-005 | IT-009 | — |
| US-001.EC-10 | Large participant list | — | IT-010 | — |
| US-002 | Govern approved listing sources | UT-011–UT-018 | IT-011–IT-020 | E2E-002 |
| US-002.EC-1 | Invalid address, protocol, or redirect | UT-016–UT-018 | IT-011 | — |
| US-002.EC-2 | Missing compliance reviews | UT-012 | IT-012 | — |
| US-002.EC-3 | Source request limit reached | UT-015 | IT-013 | — |
| US-002.EC-4 | Broker changes source | UT-009 | IT-014 | — |
| US-002.EC-5 | Concurrent source edit | UT-014 | IT-015 | — |
| US-002.EC-6 | Interrupted activation | UT-013 | IT-016 | — |
| US-002.EC-7 | Duplicate source/city | UT-011 | IT-017 | — |
| US-002.EC-8 | Activation before reviews | UT-012 | IT-018 | — |
| US-002.EC-9 | Deactivation during research | — | IT-019 | — |
| US-002.EC-10 | Source inventory at 100x volume | — | IT-020 | — |
| US-003 | Conversational request intake | UT-024–UT-028, UT-048–UT-050 | IT-021–IT-030 | E2E-003 |
| US-003.EC-1 | Hostile or unparseable input | UT-048 | IT-021 | — |
| US-003.EC-2 | Blank request | UT-024 | IT-022 | — |
| US-003.EC-3 | Request length boundary | UT-025 | IT-023 | — |
| US-003.EC-4 | Unauthenticated or suspended submission | UT-009 | IT-024 | — |
| US-003.EC-5 | Concurrent messages | — | IT-025 | — |
| US-003.EC-6 | Reconnect restores draft | — | IT-026 | — |
| US-003.EC-7 | Retried message | UT-047 | IT-027 | — |
| US-003.EC-8 | Confirm with unresolved clarification | UT-045 | IT-028 | — |
| US-003.EC-9 | Unsupported inventory | UT-026 | IT-029 | — |
| US-003.EC-10 | Many supported preferences | UT-027 | IT-030 | — |
| US-004 | Confirm classified criteria | UT-024–UT-028 | IT-031–IT-040 | E2E-004 |
| US-004.EC-1 | Invalid or contradictory criteria | UT-024, UT-028 | IT-031 | — |
| US-004.EC-2 | No hard requirements acknowledgment | UT-027 | IT-032 | — |
| US-004.EC-3 | Criteria selection limits | UT-025 | IT-033 | — |
| US-004.EC-4 | Cross-account draft access | UT-009 | IT-034 | — |
| US-004.EC-5 | Stale confirmation | UT-046 | IT-035 | — |
| US-004.EC-6 | Confirmation reconnect outcome | — | IT-036 | — |
| US-004.EC-7 | Duplicate confirmation | UT-047 | IT-037 | — |
| US-004.EC-8 | Confirmation before review | UT-045 | IT-038 | — |
| US-004.EC-9 | Discarded draft or suspended account | UT-044 | IT-039 | — |
| US-004.EC-10 | Large confirmed preference set | UT-027 | IT-040 | — |
| US-005 | Authorize included unit or overage | UT-037–UT-042 | IT-041–IT-050 | E2E-005 |
| US-005.EC-1 | Invalid plan state | UT-037 | IT-041 | — |
| US-005.EC-2 | Allowance unavailable | UT-037 | IT-042 | — |
| US-005.EC-3 | Allowance changes before opening | UT-041 | IT-043 | — |
| US-005.EC-4 | Suspended broker accepts overage | UT-009 | IT-044 | — |
| US-005.EC-5 | Concurrent last included unit | UT-041 | IT-045 | — |
| US-005.EC-6 | Reconnect after acceptance | — | IT-046 | — |
| US-005.EC-7 | Retried authorization | UT-042 | IT-047 | — |
| US-005.EC-8 | Overage before confirmation | UT-038 | IT-048 | — |
| US-005.EC-9 | Plan expires on quote screen | UT-041 | IT-049 | — |
| US-005.EC-10 | Large usage history | — | IT-050 | — |
| US-006 | Progressive verified research | UT-019–UT-023, UT-043–UT-047 | IT-051–IT-060 | E2E-006 |
| US-006.EC-1 | Malformed source records | UT-019–UT-021 | IT-051 | — |
| US-006.EC-2 | No source city coverage | UT-013 | IT-052 | — |
| US-006.EC-3 | Source limit during retrieval | UT-015 | IT-053 | — |
| US-006.EC-4 | Cross-account case access | UT-009 | IT-054 | — |
| US-006.EC-5 | Concurrent duplicate properties | UT-033–UT-035 | IT-055 | — |
| US-006.EC-6 | Browser disconnect or service restart | UT-043 | IT-056 | — |
| US-006.EC-7 | Retried completed retrieval | UT-022 | IT-057 | — |
| US-006.EC-8 | Update before LiveView mount | UT-043 | IT-058 | — |
| US-006.EC-9 | Listing becomes unavailable | UT-023 | IT-059 | — |
| US-006.EC-10 | Candidate volume at 100x | UT-036 | IT-060 | — |
| US-007 | Exact and near-match control | UT-029–UT-036, UT-043–UT-047 | IT-061–IT-070 | E2E-007 |
| US-007.EC-1 | Near-match lacks stated compromise | UT-032 | IT-061 | — |
| US-007.EC-2 | No exact or near matches | UT-029 | IT-062 | — |
| US-007.EC-3 | Many near-matches | UT-036 | IT-063 | — |
| US-007.EC-4 | Cross-account near-match approval | UT-009 | IT-064 | — |
| US-007.EC-5 | Concurrent final-position approvals | UT-046 | IT-065 | — |
| US-007.EC-6 | Interrupted approval | — | IT-066 | — |
| US-007.EC-7 | Retried approval | UT-047 | IT-067 | — |
| US-007.EC-8 | Approval before search settles | UT-044 | IT-068 | — |
| US-007.EC-9 | Approved property unavailable | UT-023 | IT-069 | — |
| US-007.EC-10 | Hundreds of tied candidates | UT-035–UT-036 | IT-070 | — |
| US-008 | Evidence-backed recommendations | UT-019–UT-023, UT-048–UT-052 | IT-071–IT-080 | E2E-008 |
| US-008.EC-1 | Unsafe evidence link | UT-016–UT-018 | IT-071 | — |
| US-008.EC-2 | Missing optional fact | UT-030, UT-049 | IT-072 | — |
| US-008.EC-3 | Oversized evidence or explanation | UT-050 | IT-073 | — |
| US-008.EC-4 | Unauthorized evidence access | UT-009 | IT-074 | — |
| US-008.EC-5 | Evidence changes while viewed | UT-023 | IT-075 | — |
| US-008.EC-6 | Interrupted explanation | UT-052 | IT-076 | — |
| US-008.EC-7 | Regenerated explanation | UT-049–UT-051 | IT-077 | — |
| US-008.EC-8 | Evidence deep link before recommendation | UT-043 | IT-078 | — |
| US-008.EC-9 | Source removes property | UT-023 | IT-079 | — |
| US-008.EC-10 | Extensive evidence history | UT-050 | IT-080 | — |
| US-009 | Generate client-ready summary | UT-053–UT-057 | IT-081–IT-090 | E2E-009 |
| US-009.EC-1 | Invalid link before generation | UT-053 | IT-081 | — |
| US-009.EC-2 | Empty shortlist | UT-054 | IT-082 | — |
| US-009.EC-3 | Summary length limit | UT-055 | IT-083 | — |
| US-009.EC-4 | Cross-account summary request | UT-009 | IT-084 | — |
| US-009.EC-5 | Concurrent generation and shortlist change | UT-056 | IT-085 | — |
| US-009.EC-6 | Interrupted generation | UT-052 | IT-086 | — |
| US-009.EC-7 | Repeated generation | UT-057 | IT-087 | — |
| US-009.EC-8 | Unapproved near-match | UT-053 | IT-088 | — |
| US-009.EC-9 | Shared property becomes unavailable | UT-023 | IT-089 | — |
| US-009.EC-10 | Many shortlist versions | UT-056 | IT-090 | — |
| US-010 | Feedback and exact-first replacement | UT-058–UT-062 | IT-091–IT-100 | E2E-010 |
| US-010.EC-1 | Invalid verdict or reason | UT-058 | IT-091 | — |
| US-010.EC-2 | Missing unsuitable reason | UT-059 | IT-092 | — |
| US-010.EC-3 | Oversized note | UT-060 | IT-093 | — |
| US-010.EC-4 | Cross-account feedback | UT-009 | IT-094 | — |
| US-010.EC-5 | Concurrent conflicting verdicts | UT-046 | IT-095 | — |
| US-010.EC-6 | Reconnect after rejection | — | IT-096 | — |
| US-010.EC-7 | Retried feedback | UT-062 | IT-097 | — |
| US-010.EC-8 | Feedback before shortlist entry | UT-061 | IT-098 | — |
| US-010.EC-9 | Feedback on removed entry | UT-061 | IT-099 | — |
| US-010.EC-10 | Exhausted replacement pool | UT-061 | IT-100 | — |
| US-011 | Seven-day case refinement | UT-024–UT-028, UT-043–UT-047 | IT-101–IT-110 | E2E-011 |
| US-011.EC-1 | Invalid refined criteria | UT-024–UT-028 | IT-101 | — |
| US-011.EC-2 | No confirmed criteria | UT-044 | IT-102 | — |
| US-011.EC-3 | Boundary passes while editing | UT-044 | IT-103 | — |
| US-011.EC-4 | Cross-account refinement | UT-009 | IT-104 | — |
| US-011.EC-5 | Concurrent refinements | UT-046 | IT-105 | — |
| US-011.EC-6 | Interrupted unconfirmed refinement | UT-043 | IT-106 | — |
| US-011.EC-7 | Retried reconfirmation | UT-047 | IT-107 | — |
| US-011.EC-8 | Share during refinement draft | UT-053 | IT-108 | — |
| US-011.EC-9 | Suspension or expiry during refinement | UT-044 | IT-109 | — |
| US-011.EC-10 | Many refinement versions | UT-043 | IT-110 | — |
| US-012 | Audit usage, overages, and credits | UT-037–UT-042 | IT-111–IT-120 | E2E-012 |
| US-012.EC-1 | Invalid ledger event | UT-039 | IT-111 | — |
| US-012.EC-2 | Empty usage history | UT-040 | IT-112 | — |
| US-012.EC-3 | Allowance and period boundaries | UT-037–UT-040 | IT-113 | — |
| US-012.EC-4 | Unauthorized ledger access | UT-009 | IT-114 | — |
| US-012.EC-5 | Concurrent completion and credit | UT-042 | IT-115 | — |
| US-012.EC-6 | Interrupted credit evaluation | UT-042 | IT-116 | — |
| US-012.EC-7 | Replayed ledger workflows | UT-042 | IT-117 | — |
| US-012.EC-8 | Premature credit request | UT-038 | IT-118 | — |
| US-012.EC-9 | Result arrives after credit | UT-042 | IT-119 | — |
| US-012.EC-10 | Ledger volume at 100x | UT-040 | IT-120 | — |

### Components and Interfaces

| Source | Responsibility | Unit | Integration | E2E |
| --- | --- | --- | --- | --- |
| `Accounts.Invitation` | Validate, issue, accept, expire and replay invitations | UT-001–UT-005 | IT-001–IT-010 | E2E-001 |
| `Accounts.Authorization` | System role, membership, status and non-leaking denial | UT-006–UT-010 | IT-004, IT-008, IT-024, IT-034, IT-054 | E2E-001 |
| `Sources` | Compliance, lifecycle, concurrency and adapter registry | UT-011–UT-015 | IT-011–IT-020 | E2E-002 |
| `SourceHTTP` | HTTPS, host, redirect, limits and failure classes | UT-016–UT-018 | IT-011, IT-013 | E2E-002 |
| `Ingestion.Adapter` | Fetch/normalize contract and errors | UT-019–UT-023 | IT-051–IT-057 | E2E-006 |
| `Criteria` | Supported schema, bounds and cross-field validation | UT-024–UT-028 | IT-021–IT-040 | E2E-003–E2E-004 |
| `Ranking` | Eligibility, unknowns, scoring, dedup and order | UT-029–UT-036 | IT-055, IT-060–IT-080 | E2E-006–E2E-008 |
| `Usage` | Quote, append-only consume and credit contracts | UT-037–UT-042 | IT-041–IT-050, IT-111–IT-120 | E2E-005, E2E-012 |
| `SearchCases` | State, persistence, versioning, stale and idempotent commands | UT-043–UT-047 | IT-025–IT-110 | E2E-003–E2E-011 |
| `AI.Provider` and projection | Structured response, allowlisted evidence and fallback | UT-048–UT-052 | IT-021, IT-076–IT-077 | E2E-003, E2E-008 |
| `Summary` | Eligibility, content policy, staleness and idempotency | UT-053–UT-057 | IT-081–IT-090 | E2E-009 |
| `Feedback` | Verdict validation and replacement selection | UT-058–UT-062 | IT-091–IT-100 | E2E-010 |
| Broker LiveViews | Authenticated intake, case, refinement and reconnect surfaces | — | IT-026, IT-036, IT-046, IT-056 | E2E-003–E2E-011 |
| Admin LiveViews | Broker, source and usage governance | — | IT-004, IT-014, IT-114 | E2E-001–E2E-002, E2E-012 |
| Oban workers | Durable retrieval, recompute, deadline, credit and retention | — | IT-019–IT-020, IT-051–IT-060, IT-115–IT-119 | E2E-006 |
| Browser route/event contract | Success and stable denial/stale/error rendering for every route | UT-009 | IT-004, IT-008, IT-014, IT-024, IT-034, IT-054, IT-064, IT-074, IT-084, IT-094, IT-104, IT-114 | E2E-001–E2E-012 |

## Unit Tests

### Accounts and Authorization

- **UT-001** (error): `Invitation.changeset/2` with `email: "not-an-email"` returns an email format error and no valid insert changeset.
- **UT-002** (error): `Invitation.changeset/2` with blank `name` or `email` reports the exact required fields.
- **UT-003** (boundary): `Accounts.invite_broker/3` at the configured active-plus-pending participant limit returns `{:error, :pilot_limit_reached}`.
- **UT-004** (boundary): `Invitation.usable?/2` is true one second before `expires_at` and false at `expires_at`.
- **UT-005** (state): `Invitation.usable?/2` returns false for `accepted` and `revoked` records and maps replay to `:already_accepted` or `:revoked`.
- **UT-006** (happy): `Authorization.authorize/3` permits an active member to read and mutate its own account resources.
- **UT-007** (happy): `Authorization.authorize/3` permits a system administrator to use documented cross-account admin operations.
- **UT-008** (error): a member without an account membership receives `:not_found` for a foreign case resource.
- **UT-009** (error): a non-admin or suspended actor receives `:unauthorized` or `:suspended` for the relevant command without resource details.
- **UT-010** (state): suspension invalidates active membership mutation permission even when a session token was issued earlier.

### Sources, HTTP, Listings, and Evidence

- **UT-011** (error): `Sources.change_source/2` rejects duplicate normalized base URL plus city with the source/city uniqueness error.
- **UT-012** (state): `Sources.activate/2` returns missing terms, robots, method, review date, adapter, and city prerequisites as field-specific errors.
- **UT-013** (state): a source transition allows draft to active only after prerequisites, active to degraded/inactive, and rejects direct inactive-to-active without review.
- **UT-014** (concurrency): a stale `lock_version` passed to `Sources.update_source/3` returns `{:error, :stale}`.
- **UT-015** (boundary): `RateLimit.allow?/3` permits exactly the configured request count and returns retry time for the next request.
- **UT-016** (error): `SafeURL.validate/2` rejects HTTP, userinfo, fragments used as alternate targets, and non-HTTP schemes.
- **UT-017** (error): `SafeURL.validate_redirect/3` rejects a redirect whose final host is absent from the source allowlist.
- **UT-018** (error): `SafeURL.resolve/2` rejects loopback, private, link-local, and metadata-service IP destinations.
- **UT-019** (happy): a reference adapter normalizes a BRL price, decimal square meters, supported city/type, and canonical HTTPS link into `NormalizedListing`.
- **UT-020** (error): normalization returns field-specific errors for missing price, missing location, unsupported transaction/type/city, and malformed numerics.
- **UT-021** (boundary): normalization distinguishes unknown optional bedrooms, bathrooms, parking, and area from numeric zero.
- **UT-022** (idempotency): `Listings.upsert_snapshot/2` with the same source/external ID and data hash returns the existing snapshot.
- **UT-023** (state): `Listings.mark_unavailable/2` preserves snapshots/evidence, changes current availability, and returns affected open research-run IDs.

### Criteria and Ranking

- **UT-024** (error): `Criteria.validate/1` rejects negative values, inverted ranges, blank selections, and contradictory minimum/maximum entries.
- **UT-025** (boundary): request length, free-form value length, selection count, and criterion count pass at the documented maximum and fail one unit above it.
- **UT-026** (error): transaction/type/city normalization rejects rental, commercial, land, rural, development-only, and non-pilot-city inputs with `:unsupported_inventory`.
- **UT-027** (state): a criteria set with only preferences requires `all_inventory_acknowledged: true`; a large allowed preference set round-trips without omission.
- **UT-028** (happy): every supported criterion serializes with `kind`, operator, normalized value, and `hard` or `preference` classification and round-trips through JSONB.
- **UT-029** (happy): `Ranking.evaluate/3` places candidates satisfying all hard requirements in `exact` and those failing known hard values in `near`.
- **UT-030** (state): an unknown field never satisfies a hard requirement, earns preference points, or appears as a positive reason.
- **UT-031** (boundary): ranking `v1` scores remain from 0 through 100 for generated valid criteria/property inputs.
- **UT-032** (error): a near-match without evidence sufficient to name every failed hard requirement is rejected as `:insufficient_evidence`.
- **UT-033** (happy): source identity and exact normalized dedup keys collapse duplicates while preserving alternate listing provenance.
- **UT-034** (state): similarity below the high-confidence merge threshold leaves candidates distinct and marks `possible_duplicate`.
- **UT-035** (ordering): equal scores resolve by verification time, completeness, source confidence, then cluster UUID.
- **UT-036** (ordering): permuting the same 1,000 candidate inputs produces the same ordered top exact and near-match sets with bounded page results.

### Usage and Case State

- **UT-037** (boundary): `Usage.quote_case/2` returns included for trial unit 10 and paid unit 30, blocked after trial exhaustion/expiry, and BRL 500 overage after paid exhaustion.
- **UT-038** (error): consumption without confirmed criteria/current quote or credit before terminal failure returns the documented prerequisite error.
- **UT-039** (error): ledger changesets reject zero/invalid units, negative amounts, missing account/case/period, and mismatched causation.
- **UT-040** (happy): summing an empty ledger is zero and summing include, overage, and credit events yields exact allowance and BRL totals at period boundaries.
- **UT-041** (concurrency): quote version comparison detects a changed billing period or balance and returns `:usage_changed` before insertion.
- **UT-042** (idempotency): duplicate consumption or credit business keys resolve to one event and a credited case cannot affect balance twice.
- **UT-043** (state): `CaseView.project/2` derives current persisted draft, run, match, shortlist, and summary state without PubSub history.
- **UT-044** (boundary): refinement is allowed one second before `refinement_expires_at`, rejected at the timestamp, and never changes the saved terminal run state to `expired`.
- **UT-045** (state): confirmation rejects drafts without completed classification review or with an unresolved clarification.
- **UT-046** (concurrency): stale draft, criteria, source, shortlist, and feedback versions map to `{:error, :stale}`.
- **UT-047** (idempotency): repeated message, opening, confirmation, refinement, approval, feedback, and summary command keys return the original result without a second effect.

### AI, Summary, and Feedback

- **UT-048** (error): `AI.interpret/2` rejects provider output with invented criteria, invalid schema, multiple clarifications, or subjective neighborhood claims.
- **UT-049** (happy): `EvidenceProjection.build/2` includes only fields with current verified evidence and attaches field/snapshot identifiers.
- **UT-050** (boundary): evidence projection and narrative enforce item, character, and history limits while retaining decisive unknowns, compromises, links, and provenance.
- **UT-051** (error): `AI.validate_narrative/2` rejects an attribute or claim whose evidence identifier is absent from the projection.
- **UT-052** (state): provider timeout, malformed output, or unavailable model produces `:narrative_unavailable` and preserves deterministic reasons.
- **UT-053** (error): `Summary.build/2` excludes unavailable entries, unsafe links, unapproved near-matches, and all broker-only scores, costs, and diagnostics.
- **UT-054** (error): summary generation for an empty or not-ready shortlist returns `{:error, :shortlist_not_ready}`.
- **UT-055** (boundary): the concise summary renderer stays within the documented copy limit without dropping links or compromises.
- **UT-056** (state): a summary references exactly one shortlist version and reports stale when a newer version exists.
- **UT-057** (idempotency): repeated summary generation for the same shortlist version and command key returns the same body and one snapshot.
- **UT-058** (error): feedback changeset rejects unknown verdicts and unsuitable reason values.
- **UT-059** (error): unsuitable feedback without a reason returns a required-field error while useful feedback requires none.
- **UT-060** (boundary): a note passes at the documented maximum and fails one character above without losing selected reason.
- **UT-061** (state): replacement skips rejected/unavailable clusters, selects the next exact candidate, and returns a separate near-match proposal only when exact candidates are exhausted.
- **UT-062** (idempotency): retrying feedback produces one current verdict and at most one replacement shortlist version.

## Integration Tests

### Pilot Access — US-001

- **IT-001**: submit `bad-email` in `Admin.BrokerLive.Index`; the form renders the email correction and `invitations` remains empty.
- **IT-002**: submit an invitation with blank name, then blank email; each required error renders and no mail or row is created.
- **IT-003**: seed the configured number of active/pending participants and invite one more; the LiveView renders the limit and inserts nothing.
- **IT-004**: an authenticated broker navigates to `/admin/brokers` and invokes invite/suspend events; access is denied and no account identity is exposed or changed.
- **IT-005**: two administrator transactions invite `broker@example.com` behind a barrier; one pending row and one usable token exist, and both callers receive its current state.
- **IT-006**: create an invitation, load activation, disconnect before password submit, then reopen the token; the same invitation completes one user/account/membership.
- **IT-007**: accept an invitation and revisit its token; the UI directs the matching user to login and creates no duplicate user or membership.
- **IT-008**: while signed in as `other@example.com`, open an invitation for `broker@example.com`; activation requires sign-out and changes neither identity.
- **IT-009**: open expired, revoked, and accepted tokens; each renders the correct generic state, creates no account, and leaks no token metadata.
- **IT-010**: seed 500 participants; administrator search and pagination return the requested page, while broker rows expose no cases or usage details.

### Source Governance — US-002

- **IT-011**: create sources with HTTP, unsupported scheme, private-IP host, and redirect to an unapproved host; drafts may retain safe input but activation renders the invalid field and performs no request.
- **IT-012**: save a source without terms or robots review; it persists as draft and activation lists both missing prerequisites.
- **IT-013**: configure two requests per minute and run three fetch jobs; two call the local endpoint, the third becomes rate-limited with retry time and no false success.
- **IT-014**: a broker posts source create/activate LiveView events; authorization rejects them and source configuration is not rendered.
- **IT-015**: two admins edit the same `lock_version`; the first succeeds, the second renders stale-state guidance and does not overwrite fields.
- **IT-016**: interrupt activation between validation and transaction completion; rollback leaves one visible draft state and retry activates it once.
- **IT-017**: submit the same normalized source/city twice; the unique constraint returns the existing record or duplicate warning with one coverage row.
- **IT-018**: invoke activation directly before compliance completion; the context returns field prerequisites and status remains draft.
- **IT-019**: deactivate a source while a research run has an active attempt; persisted evidence remains visible, no further page job is enqueued, and other attempts continue.
- **IT-020**: process 100 bounded fixture pages concurrently; queue limits hold, snapshots upsert without duplication, and the admin/broker views remain paginated.

### Request Intake — US-003

- **IT-021**: the fake provider returns hostile/unparseable/non-property output; the draft persists the broker message, renders a safe restatement prompt, and stores no criteria.
- **IT-022**: submit an empty or whitespace-only message; the LiveView renders the required request prompt and inserts no message or AI job.
- **IT-023**: submit exactly the documented maximum then one character above; the first persists intact, the second renders the limit and preserves the editor text without truncation.
- **IT-024**: unauthenticated and suspended sessions submit a draft event; each is redirected/denied, with no message, interpretation, AI call, or usage event.
- **IT-025**: submit two distinct client message IDs concurrently; both persist once with unique stable sequence numbers and no case opens.
- **IT-026**: submit a message, persist a clarification, terminate the LiveView, and remount; the saved conversation and unresolved question render.
- **IT-027**: submit the same client message ID twice; one message and interpretation exist, the original result returns, and usage remains empty.
- **IT-028**: attempt confirmation while an unresolved clarification exists; the UI renders that item and creates no criteria version or case.
- **IT-029**: interpret rental, commercial, land, rural, development-only, and non-pilot city requests; each unsupported part renders and the editable draft remains.
- **IT-030**: interpret the maximum allowed preference set; every item renders in review and the stored proposal contains the full set.

### Criteria Confirmation — US-004

- **IT-031**: submit inverted price/area ranges, negative counts, and contradictory city/type entries; every conflict renders and no confirmation is inserted.
- **IT-032**: confirm preference-only criteria without acknowledgment, then with it; the first is blocked and the second creates the exact criteria version.
- **IT-033**: submit one more criterion/selection/value character than each supported limit; the relevant limit renders and the prior valid draft remains.
- **IT-034**: account B opens account A's draft URL and event; both return not found without criteria, owner, or existence details.
- **IT-035**: tab A edits draft version 2 while tab B confirms expected version 1; B receives stale guidance and no version is confirmed.
- **IT-036**: disconnect immediately after confirmation commit and remount; the page shows the saved criteria version and whether the case-opening quote/action completed.
- **IT-037**: send the same confirmation key twice; one criteria version and at most one opening authorization result exist.
- **IT-038**: call confirmation before classification review; the context returns `:review_required`, the UI opens review, and no usage operation runs.
- **IT-039**: discard the draft and separately suspend its account before confirmation; both attempts fail with the accurate state and no unit is consumed.
- **IT-040**: confirm the maximum large preference set; the full JSONB version round-trips and the rendered summary exposes every criterion.

### Usage Authorization — US-005

- **IT-041**: remove or corrupt the active plan fixture and open a case; the context returns `:usage_blocked`, guidance renders, and no case/event/job exists.
- **IT-042**: hold the allowance query unavailable with a database error boundary; the UI shows temporary unavailability and assumes neither included nor overage.
- **IT-043**: show an included quote, consume the final unit elsewhere, then submit; the original action returns `:usage_changed` and renders BRL 5 consent before creation.
- **IT-044**: suspend a broker after rendering overage consent and submit acceptance; no authorization, case, or ledger event is inserted.
- **IT-045**: two sessions open cases against the final included unit concurrently; one consumes it and the other receives a current overage-required result.
- **IT-046**: accept overage and disconnect after commit; remount shows the one opened case and never prompts for duplicate consent.
- **IT-047**: retry confirmation and overage acceptance with the same keys; one case, one acceptance, one consumption effect, and one initial research job exist.
- **IT-048**: submit overage acceptance for an unconfirmed draft; it returns the missing prerequisite and creates no records.
- **IT-049**: expire the plan after quote render and before submit; version validation blocks creation and forces the updated plan state to render.
- **IT-050**: seed 5,000 ledger-backed cases; allowance totals equal ledger sums and the broker history returns stable cursor-paginated pages.

### Progressive Research — US-006

- **IT-051**: process fixture records with unsafe links, missing/invalid prices, missing locations, and malformed shapes; each is excluded, error counts persist, and source status is accurate.
- **IT-052**: open a case for a pilot city with no active source coverage; the run finalizes empty with coverage-gap reason, no fabricated candidate, and no technical-failure credit.
- **IT-053**: rate-limit a source mid-run; verified local results remain, its attempt is incomplete/rate-limited, and other sources finish.
- **IT-054**: account B opens account A's case route/event; both return not found without criteria, results, or source diagnostics.
- **IT-055**: two source jobs insert the same high-confidence property concurrently; constraints and clustering yield one candidate with both provenance records.
- **IT-056**: persist a searching run, stop/restart worker supervision, then drain jobs and remount; progress resumes from persisted attempts and subsequent updates render.
- **IT-057**: replay a completed collection run and normalization job; listing, snapshot, match, and visible candidate counts do not increase.
- **IT-058**: complete recomputation and broadcast before `CaseLive` mounts; mount queries current state and renders the new candidate without needing the missed event.
- **IT-059**: mark a shortlisted listing unavailable; recomputation removes eligibility, creates a new shortlist version, and applies exact-before-near replacement.
- **IT-060**: evaluate 10,000 prefilter candidates from the large fixture; results are stable and paginated, raw bodies are not loaded, and deadline finalization remains schedulable.

### Shortlist Control — US-007

- **IT-061**: persist a near-match with an unknown failed requirement; approval returns `:insufficient_evidence` and no shortlist entry is added.
- **IT-062**: finalize a run with no exact or approvable near matches; `CaseLive` renders empty guidance and no shortlist entries.
- **IT-063**: persist 1,000 near matches; the initial view renders the bounded top page with cursor access to the next stable page.
- **IT-064**: account B submits approval for account A's near match; the action returns not found and inserts no approval or shortlist version.
- **IT-065**: two sessions approve different near matches for one open position with the same expected version; one succeeds and one receives stale state.
- **IT-066**: commit a near-match approval then terminate the client before response; remount shows the one approved entry and compromise record.
- **IT-067**: retry the same approval key; one approval, one occupied position, and one resulting shortlist version exist.
- **IT-068**: approve a near match while research remains searching, then add an exact match; the near match stays labeled and is not silently displaced.
- **IT-069**: make an approved exact or near-match property unavailable; it leaves the active version and replacement never auto-approves a near match.
- **IT-070**: rank 500 identical-score candidates in repeated/permuted jobs; the same three cluster UUIDs appear in the same order.

### Recommendation Evidence — US-008

- **IT-071**: attach HTTP, private-host, or unapproved-redirect evidence links; projection omits the link and the property cannot become recommended.
- **IT-072**: recommend a property with unknown optional parking; the UI renders unknown and neither deterministic nor generated reasons claim parking.
- **IT-073**: attach maximum-plus-one evidence history/narrative payload; the primary view remains bounded while complete decisive evidence is available in a paginated detail view.
- **IT-074**: a user without case membership opens an evidence deep link; the response is not found and reveals no property or source.
- **IT-075**: update a listing snapshot while evidence view is open; PubSub reload shows the new verification/availability and does not display stale facts as current.
- **IT-076**: make the AI provider time out during explanation; deterministic reasons, evidence, and shortlist actions remain usable with narrative-unavailable status.
- **IT-077**: regenerate an explanation against the same evidence watermark; one current narrative contains only allowlisted facts and no duplicate recommendation is created.
- **IT-078**: open an evidence deep link before a recommendation projection exists; the view renders pending/unavailable rather than a factual record.
- **IT-079**: deactivate/remove the current source listing; recommendation becomes unavailable and cannot enter a new client summary.
- **IT-080**: seed 1,000 historical snapshots for a property; the default query returns current decisive evidence and paginated provenance without loading raw bodies.

### Client Sharing — US-009

- **IT-081**: invalidate a shortlisted source link immediately before generation; the affected entry is blocked/excluded and no ready summary claims it.
- **IT-082**: generate from an empty or not-ready shortlist; the LiveView renders the reason and inserts no summary snapshot.
- **IT-083**: generate from three verbose properties; the copy body stays within the configured limit and retains every link and compromise.
- **IT-084**: account B requests account A's summary route/event; it returns not found and inserts nothing.
- **IT-085**: session A generates while session B commits a newer shortlist version; the snapshot records its source version and renders stale before copy.
- **IT-086**: interrupt optional narrative generation; no incomplete narrative is marked ready and the broker may generate/copy the deterministic summary.
- **IT-087**: repeat generation with the same shortlist version/key; body, timestamp record, and absence of client-contact rows remain consistent.
- **IT-088**: include an unapproved near match in candidates and generate; it is excluded and the readiness prerequisite renders.
- **IT-089**: make a previously summarized property unavailable; later summaries exclude it and the active shortlist visibly changes without rewriting history.
- **IT-090**: seed 100 historical shortlist versions; generation selects only the current ready version with bounded indexed queries.

### Recommendation Feedback — US-010

- **IT-091**: submit an unknown verdict and invalid unsuitable reason; validation renders and shortlist/version counts remain unchanged.
- **IT-092**: submit unsuitable without reason; the UI preserves the form, requests a reason, and performs no replacement.
- **IT-093**: submit a note one character over the limit; the limit renders while verdict/reason remain selected and no feedback commits.
- **IT-094**: account B submits feedback for account A; the action returns not found and reveals no recommendation state.
- **IT-095**: two sessions submit conflicting verdicts against one feedback version; one commits and the other receives stale state before changing it.
- **IT-096**: commit rejection and exact replacement then disconnect; remount displays one verdict and the replacement shortlist.
- **IT-097**: retry the rejection key; one current verdict and one replacement mutation exist.
- **IT-098**: mark a ranked candidate unsuitable before it enters the shortlist; feedback persists for analysis but no shortlist position changes.
- **IT-099**: submit feedback for an unavailable/already removed entry; current state renders and no second replacement occurs.
- **IT-100**: reject candidates until exacts are exhausted; selection never cycles rejected clusters and returns one separate near-match proposal or exhausted state.

### Case Refinement — US-011

- **IT-101**: submit invalid/unsupported refined criteria; validation renders and the existing confirmed criteria/research/shortlist remain current.
- **IT-102**: invoke refinement for a case without confirmed criteria; it returns to intake and creates no version or usage event.
- **IT-103**: load refinement one second before expiry and submit at expiry; confirmation is blocked and a new-case usage quote renders.
- **IT-104**: account B opens/submits account A's refinement; both return not found and reveal no criteria.
- **IT-105**: two sessions refine version 1 concurrently; one creates version 2 and the other receives stale reconciliation with no version 3.
- **IT-106**: save an unconfirmed refinement draft and disconnect; the last confirmed version remains active/shareable and the draft resumes before expiry.
- **IT-107**: retry reconfirmation with the same key; one criteria/research version is created and the ledger gains no usage event.
- **IT-108**: request sharing from an unconfirmed refinement; summary uses the last ready confirmed shortlist and labels the draft as not applied.
- **IT-109**: suspend the account and separately cross expiry before refinement submit; each blocks with its accurate reason and no version.
- **IT-110**: seed 100 refinements; the current version renders directly and history paginates in descending version order.

### Usage Administration — US-012

- **IT-111**: attempt direct inserts with invalid units, cents, missing case, and foreign account attribution; changesets/constraints reject every event and totals stay unchanged.
- **IT-112**: open admin usage for an account with no ledger; it renders zero included, overage, credit, and cost totals with an empty history state.
- **IT-113**: create events exactly at trial expiry, allowance exhaustion, billing-period end/start, and month rollover; each belongs to the correct quote/period and totals.
- **IT-114**: a broker and a non-privileged user request another account's ledger; access is denied without totals or case identity.
- **IT-115**: finalize a zero-result technical failure and run two credit workers concurrently; one credit affects the ledger and both resolve to the same decision.
- **IT-116**: crash credit evaluation after enqueue and rerun it; the case reaches one final auditable credited state without ambiguous balance.
- **IT-117**: replay case opening, failure finalization, and credit jobs; consumption and credit each affect balance exactly once.
- **IT-118**: request credit for searching, complete-with-results, partial-with-results, and legitimate-empty runs; each waits or returns ineligible with no credit.
- **IT-119**: insert a verified result after a credited terminal run through an administrative conflict fixture; the ledger remains unchanged and an audit conflict is recorded/visible.
- **IT-120**: seed the large ledger fixture; totals equal direct aggregate truth, itemized history paginates stably, and reconciliation does not load raw evidence.

## End-to-End Tests

### Administrator and Broker Journeys

- **E2E-001**: an administrator opens `/admin/brokers`, invites
  `ana@example.com`, Ana follows the single-use link, establishes the generated
  auth password, signs in, and sees the 14-day/10-case trial; the administrator
  suspends Ana, her active LiveView disconnects and billable actions stop, then
  restoration permits login and access to the same historical cases.

- **E2E-002**: an administrator creates a source draft with an HTTPS host,
  registered fixture adapter, Americana/Santa Bárbara d'Oeste/Nova Odessa
  coverage, permitted method, terms/robots reviewers and dates, and rate limit;
  activation makes fixture listings eligible for a new case, degradation stops
  on-demand reliance while disclosing status, and deactivation preserves prior
  evidence while blocking new retrieval.

- **E2E-003**: an active broker opens `/requests/new`, submits “Apartamento em
  Americana até R$ 500 mil, 2 quartos, perto de parque”, receives one objective
  clarification for ambiguous “perto”, answers it, and sees all supported
  proposed criteria classified for review; no case or usage event exists during
  drafting, and reconnecting restores the persisted conversation.

- **E2E-004**: from the interpreted request, the broker edits price and changes
  parking from preference to hard requirement, reviews every classification,
  confirms version 1, and sees the exact preserved criteria; a listing with
  unknown parking fails hard eligibility and earns no preference claim in the
  rendered preview.

- **E2E-005**: a broker with one included unit sees “uses one included case,”
  confirms, and opens exactly one searching case/event despite a repeated
  submit; after paid activation and 30 consumed cases, the next request renders
  BRL 5 and opens only after explicit acceptance, while an exhausted trial is
  blocked pending administrator activation.

- **E2E-006**: opening a case immediately renders verified indexed candidates;
  manual Oban draining completes one source, fails another, recomputes and
  updates `CaseLive` without losing broker UI state, then the injected
  ten-minute deadline finalizes the best persisted result as complete, partial,
  empty, or failed according to source outcomes and verified-property count;
  reconnect displays the same state.

- **E2E-007**: a run with two exact and three near matches renders both exacts
  in rank order and the near matches separately with every failed hard
  requirement; approving one disclosed compromise fills the third position
  with a near-match label, an unapproved option remains outside the shortlist,
  and a run with four exacts selects the deterministic top three.

- **E2E-008**: the broker opens each recommendation and sees current source,
  safe direct link, verification time, deterministic match reasons, unknowns,
  compromises, and exact field provenance; a fake AI narrative references only
  supplied evidence, and provider failure removes only the narrative while all
  factual reasoning and shortlist controls remain usable.

- **E2E-009**: after marking the current shortlist ready, the broker generates
  and copies a summary containing only approved available facts, reasons,
  compromises, safe source links, and verification times; numeric scores,
  source failures, costs, and operator data are absent, and no client name,
  phone, email, document, or delivery record is requested or persisted.

- **E2E-010**: the broker marks one recommendation useful without a reason,
  marks another unsuitable with `poor_fit` and a bounded note, and sees it
  replaced by the next exact candidate; after exacts are exhausted, the next
  near match appears separately and enters only after compromise approval, while
  rejected clusters never recur in the current version.

- **E2E-011**: within seven days the broker explicitly refines any supported
  criterion, reconfirms, and receives new criteria, research, match, and
  shortlist versions without a second usage event; prior versions remain
  auditable and the latest ready version drives sharing; at exactly seven days,
  refinement is read-only and continuing requires a newly quoted billable case.

- **E2E-012**: the administrator opens `/admin/usage` and reconciles the trial,
  paid billing period, included consumption, accepted BRL 5 overage, cases, and
  credits; a partial run with a verified property and a legitimate empty run
  remain billable, while a terminal zero-verified technical failure receives
  exactly one automatic credit attributable to the original account, case,
  period, and consumption event.

## Contract Completion Notes

- Every `US-001` through `US-012` and every documented `US-NNN.EC-N` has a
  dedicated Coverage Matrix row and stable test ID.
- Every TechSpec component and public interface has a component row with happy,
  failure, boundary, concurrency, idempotency, ordering, or state coverage as
  applicable.
- The LiveView routes are the public endpoint surface. Their successful journeys
  are covered by E2E-001 through E2E-012, and every documented authorization,
  stale-state, validation, interruption, and retry shape is covered by the
  linked integration cases.
- Production source and AI smoke tests are intentionally excluded from the
  canonical default suite until a named source and provider/model are configured.
  Adapter/provider contract behavior remains fully covered by deterministic
  fixtures and fakes.
