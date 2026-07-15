# Product Requirements Document: HouseSearch MVP

## Overview

HouseSearch is a property-research assistant for independent real estate brokers
serving residential buyers in Americana, Santa Bárbara d'Oeste, and Nova Odessa,
São Paulo. It replaces repeated searches across approved property portals and
real estate agency websites with one broker-controlled workflow: describe the
client's request, confirm how each criterion should be interpreted, receive a
ranked and evidence-backed shortlist, and prepare a concise client-ready
summary.

Independent brokers currently repeat filters across disconnected sources,
compare incomplete listings, remove duplicates, and reconstruct why a property
might fit. HouseSearch performs that research while preserving the broker's
professional role. It does not autonomously decide what a client should see,
silently relax requirements, or invent missing property and neighborhood facts.

The MVP's product promise is to return the best verified result available and,
when inventory supports it, three useful broker-approved options within ten
minutes of criteria confirmation. Each recommendation shows its evidence,
source, direct link, latest verification time, matches, unknowns, and disclosed
compromises.

## Goals

- An invited broker can turn an unstructured residential purchase request into
  confirmed hard requirements and preferences without manually rebuilding the
  same filters across multiple sources.
- The broker can see verified candidates while research continues and can
  understand complete, partial, empty, and failed outcomes.
- HouseSearch ranks distinct properties deterministically and never treats an
  unknown field as a match.
- Hard requirements are never relaxed without explicit broker approval.
- Every recommended claim is traceable to current listing evidence.
- The broker can reject unsuitable options, receive controlled replacements,
  refine the request for seven days, and generate a client-ready summary without
  storing client identity or contact data.
- Administrators can control pilot access, source authorization, geographic
  coverage, allowances, overages, credits, and manual billing from auditable
  records.
- Brokers always see and approve the usage consequence before opening a
  billable case.

## User Stories

- `US-001` covers invite-only pilot access and account lifecycle.
- `US-002` covers administrator governance of approved listing sources.
- `US-003`–`US-005` cover conversational intake, criteria confirmation, and
  usage authorization.
- `US-006`–`US-008` cover progressive research, shortlist control, and factual
  recommendation evidence.
- `US-009`–`US-010` cover client-ready sharing and recommendation feedback.
- `US-011` covers the seven-day refinement lifecycle.
- `US-012` covers allowance, overage, and technical-failure credit auditing.

[Full user stories](_user_stories.md)

## Core Features

### 1. Invite-Only Broker Access

Administrators invite, activate, suspend, and restore selected pilot brokers.
There is no public registration. An active broker sees the current trial or
paid-plan status, remaining included cases, and relevant expiry or billing
period before starting research. Suspending access blocks new sessions and
billable actions without deleting historical cases.

### 2. Administrator-Approved Source Catalog

Only administrators can register and control sources. Each source records its
covered pilot cities, permitted retrieval method, terms review, robots review,
rate limit, and review date before activation. Official APIs or feeds take
precedence when available. A source may be active, degraded, or inactive, and
one source's failure must not prevent other approved sources from contributing
results.

The MVP searches approved portals and real estate agency websites only. It does
not accept listings from brokers' informal contacts or allow brokers to add
sources.

### 3. Conversational Request Intake

The broker describes the buyer's request in natural language. HouseSearch
extracts supported criteria and asks one clarification at a time when a
load-bearing detail is ambiguous. Drafting and clarification do not consume a
usage unit.

Supported criteria are:

- price or price range;
- city and neighborhood;
- property type;
- bedrooms and bathrooms;
- parking spaces;
- floor area; and
- free-form preferences supported by listing evidence.

The assistant does not convert phrases such as "safe," "family-friendly," or
other subjective neighborhood judgments into claims about crime, schools,
demographics, protected characteristics, or resident composition. It asks the
broker to restate the underlying need as an objective, buyer-confirmed
criterion.

### 4. Broker-Confirmed Criteria

For every extracted criterion, HouseSearch proposes either `hard requirement`
or `preference`. The broker can edit values and classifications and must confirm
the complete interpretation before a case opens.

Hard requirements determine eligibility. Preferences affect ranking among
eligible properties. A missing field is `unknown`; it never counts as satisfying
either classification. The confirmed criteria version remains visible and
auditable throughout the case.

### 5. Usage Authorization and Case Opening

Criteria confirmation is the billable boundary. Before opening a case,
HouseSearch shows whether it will consume an included unit or a BRL 5 paid
overage. It then creates exactly one case and exactly one corresponding usage
event.

Trial users cannot open cases after the trial expires or its allowance is
exhausted until an administrator activates the paid plan. Paid users must
explicitly approve each overage after their included monthly allowance is
exhausted. Repeated submissions, reconnects, or retries never consume more than
one unit for the same case.

### 6. Progressive Hybrid Research

HouseSearch displays verified indexed candidates immediately when available and
continues refreshing stale approved sources. Results update while the broker
remains on the case, and reconnecting restores the persisted current state.

Research remains open for up to ten minutes after confirmation. At the deadline,
the case finishes with the best verified results available. A source failure is
disclosed but does not block results from other sources. Invalid listings are
excluded rather than repaired through unsupported inference.

### 7. Deduplication, Eligibility, and Ranking

A candidate must be an active residential sale in a supported pilot city, use a
supported property type, provide a safe direct source link, and contain both
price and location. It must satisfy every confirmed hard requirement.

HouseSearch collapses listings that confidently represent the same property.
Uncertain potential duplicates remain distinct and disclose their uncertainty
rather than being silently merged. Eligible distinct properties receive an
auditable score based on confirmed criteria, freshness, completeness, and source
confidence. The shortlist selects the three highest-ranked distinct exact
matches. It does not force variety by source, location, or trade-off profile.

### 8. Exact-Match and Near-Match Control

When at least three exact matches exist, they fill the shortlist. When fewer
than three exist, HouseSearch shows all available top exact matches and presents
near-matches in a separate section. Every near-match states each hard
requirement it fails.

A near-match enters an open shortlist position only after the broker explicitly
approves the disclosed compromise. It retains a visible near-match label. An
unapproved near-match never appears in client-ready content.

### 9. Evidence-Based Recommendations

Each recommendation includes key property facts, match reasons, unknown fields,
disclosed compromises, source, direct link, and latest verification time. Every
attribute used in an explanation must exist in verified source evidence.

Generated narrative is an enhancement, not a source of truth. If narrative is
unavailable, the factual ranking reasons and evidence remain usable. A removed
or invalid listing is marked unavailable, leaves the active shortlist, and
triggers replacement under the same exact-before-near rules.

### 10. Broker Approval and Client-Ready Summary

The broker approves the shortlist before producing client-facing content. The
summary contains key property facts, why each option matches, disclosed
compromises, source links, and latest verification times. It excludes numeric
scores, internal score breakdowns, failed-source diagnostics, costs, and other
operator information.

The broker copies or shares the summary through existing external tools.
HouseSearch does not send email or WhatsApp messages and does not request or
store the client's name, phone number, email, or documents.

### 11. Feedback and Controlled Replacement

The broker can mark a recommendation `useful` in one action. Marking it
`unsuitable` requires one reason category and permits an optional note. The MVP
reason categories are:

- listing unavailable or stale;
- listing data incorrect;
- duplicate property;
- poor fit despite the confirmed criteria;
- disclosed compromise is unacceptable; and
- other.

An unsuitable shortlist property is removed. The next exact match fills its
position automatically. If no exact match remains, HouseSearch proposes the
next near-match separately and requires broker approval. A rejected property
does not return to the current shortlist version.

Feedback affects the current shortlist through these replacement rules and
supports later ranking review. The MVP does not autonomously personalize or
change ranking rules from an individual verdict.

### 12. Seven-Day Case Refinement

The broker explicitly chooses an existing case to refine. For seven days from
the case's original confirmation, the broker may change and reconfirm any
supported criteria without consuming another unit. Each confirmation creates a
new visible criteria and shortlist version while preserving prior versions for
audit.

After the seven-day window expires, the case remains readable but cannot be
refined. Continuing the research requires a new billable case, with the normal
unit or overage authorization shown before opening.

### 13. Usage Ledger and Technical-Failure Credits

The administrator can audit included units, paid overages, search cases, manual
billing periods, and credits. The assisted trial lasts 14 days and includes 10
cases. The Founding Plan costs BRL 149 per month and includes 30 cases; each
explicitly accepted additional case costs BRL 5. Payment collection and
reconciliation are manual in the MVP.

A confirmed case normally remains billable whether it finishes complete,
partial, or legitimately empty. HouseSearch automatically restores the unit
only when platform or approved-source failures cause a terminal case to contain
zero verified properties. A partial result containing any verified property
remains billable. Consumption, acceptance, and credit events must be attributable
to exactly one account and case and must affect the balance exactly once.

## Business Rules

### Personas and Permissions

- Only active invited brokers can draft, confirm, search, refine, give feedback,
  or generate client-ready summaries.
- A broker can access only cases, usage information, and recommendations
  belonging to that broker's account.
- Only administrators can invite or suspend brokers, activate paid plans, change
  allowances, govern sources, or inspect cross-account usage records.
- A client recipient has no HouseSearch account or product permissions.

### Pilot Market

- Supported transaction: residential property sale.
- Supported cities: Americana, Santa Bárbara d'Oeste, and Nova Odessa, São
  Paulo, Brazil.
- Supported property types: houses, townhouses, condominium houses, and
  apartments.
- Rentals, commercial properties, land, rural properties, and specialized
  new-development inventory are rejected as unsupported before confirmation.

### Criteria and Matching

- Every confirmed criterion is either a hard requirement or a preference.
- The assistant proposes classifications; only the broker's confirmed version
  governs the case.
- Every hard requirement must be satisfied for an exact match.
- Unknown data never satisfies a hard requirement or earns preference credit.
- Near-matches are ineligible for the shortlist until the broker approves their
  explicit compromise.
- A shortlist contains at most three distinct available properties.
- Exact matches always take precedence over near-matches.
- Within the same data and criteria version, ranking and tie resolution must
  produce stable results.

### Case Lifecycle

- `draft`: the request may be edited and has no usage consequence.
- `awaiting confirmation`: interpreted criteria require broker review.
- `searching`: criteria are confirmed, one unit is authorized, and research is
  active.
- `complete`: research reached a terminal state with three broker-approvable
  exact matches and no unresolved material source work.
- `partial`: research reached its deadline or material sources failed, but one
  or more verified properties are available.
- `empty`: approved research completed successfully with no eligible exact or
  near-match inventory.
- `failed`: platform or source failures leave the case with zero verified
  properties.
- `expired`: seven days have elapsed since original confirmation; results remain
  readable but refinement requires a new case.

No case can enter `searching` without confirmed criteria and successful usage
authorization. Terminal result states cannot return to `searching` except
through a confirmed in-window refinement, which creates a new version. Expiry
does not delete or hide prior versions.

### Usage and Pricing

- Trial: 14 days, 10 included confirmed cases, no card required.
- Founding Plan: BRL 149 per month, 30 included confirmed cases.
- Overage: BRL 5 per additional confirmed case, accepted individually before
  case opening.
- A unit represents one confirmed client request plus unlimited messages,
  criteria changes, and shortlist versions during its seven-day refinement
  window.
- Trial exhaustion requires paid-plan activation; paid-plan exhaustion requires
  explicit overage acceptance.
- A zero-verified-property technical failure restores the unit exactly once.
- Legitimate empty results and partial results with verified properties do not
  restore the unit.
- Automated payment, checkout, invoicing, and tax-document issuance are not part
  of the MVP.

### Source and Evidence Integrity

- Only active administrator-approved sources may supply new research results.
- Source activation requires recorded terms and robots reviews, a permitted
  retrieval method, covered pilot cities, limits, and review date.
- Official APIs or feeds must be used instead of page collection when available
  and permitted.
- Every recommended property must have a valid source link, price, location, and
  latest verification time.
- A generated explanation may summarize verified evidence but may not add facts.
- Removing or deactivating a source does not erase historical evidence needed to
  audit prior recommendations.

### Feedback and Sharing

- `useful` feedback requires no reason.
- `unsuitable` feedback requires one supported reason category and may include a
  bounded optional note.
- Rejection removes the property from the current shortlist version and never
  silently admits a near-match.
- Client-ready content contains approved, currently available properties only.
- HouseSearch never requires buyer identity or contact information to generate
  or copy a summary.

## User Experience

### Broker Journey

1. An invited broker activates access and sees trial or paid-plan allowance.
2. The broker describes a residential buyer request conversationally.
3. HouseSearch asks one clarification at a time and proposes structured hard
   requirements and preferences.
4. The broker reviews every criterion and sees the unit or overage consequence.
5. Confirmation opens one case and starts progressive research.
6. The broker sees verified candidates, source availability, and freshness as
   research progresses.
7. HouseSearch produces up to three top exact matches and separates any
   near-matches requiring approval.
8. The broker reviews evidence, approves any disclosed compromise, and marks the
   final shortlist ready for the client.
9. The broker copies a concise client-ready summary into an external
   communication tool.
10. The broker records useful or unsuitable feedback. Unsuitable options receive
    exact-first controlled replacements.
11. During the next seven days, the broker may explicitly refine the case and
    repeat the confirmation, research, approval, and sharing flow without
    another unit.

### Administrator Journey

1. The administrator records and reviews approved sources and their city
   coverage before activation.
2. The administrator invites selected brokers and activates paid plans after
   manual commercial confirmation.
3. The administrator monitors source availability and degrades or deactivates
   unsafe or failing sources.
4. The administrator audits cases, included usage, explicit overages, automatic
   failure credits, and manual payment status.

### Interaction Principles

- Criteria confirmation must make hard requirements visually distinct from
  preferences and keep every value editable.
- Research states, source failures, freshness, unknown facts, and near-match
  compromises must use plain language and must not rely on color alone.
- Keyboard navigation, visible focus, semantic labels, screen-reader status
  announcements, and sufficient contrast apply to every primary flow.
- Progressive updates must not steal focus, reorder content while the broker is
  interacting with it, or erase typed feedback.
- Destructive or billable actions require an explicit consequence before
  confirmation; retries and reconnects must show the persisted outcome.

## High-Level Technical Constraints

- The user-visible research deadline is ten minutes from criteria confirmation.
  The system must show the best verified partial result at that boundary rather
  than waiting indefinitely.
- Search and recommendation state must survive browser disconnection, process
  interruption, and retry without duplicating cases, listings, feedback, usage,
  approvals, or credits.
- Approved sources may fail independently. One source failure must not prevent
  other sources from returning results.
- Every displayed property fact and generated claim must remain attributable to
  the source evidence and verification event that supplied it.
- Source access must respect recorded terms, robots directives, permitted
  integration methods, host restrictions, credentials, and rate limits.
- The product must minimize personal data under Brazil's LGPD. The MVP stores
  broker account data and property criteria but no buyer names, phone numbers,
  emails, documents, or inferred protected characteristics.
- Logs, exports, and operator views must not expose credentials, tokens, or data
  belonging to another broker account.
- The broker must retain final control over criteria, near-match approval,
  feedback, and client-facing output even when automated interpretation or
  narrative generation is unavailable.

## Non-Goals (Out of Scope)

- End-buyer accounts, buyer self-service search, and direct buyer messaging.
- Public broker registration or unassisted onboarding.
- Real estate agency teams, shared workspaces, internal permission hierarchies,
  and multi-user CRM workflows.
- Rentals, short-term rentals, commercial property, land, rural property, and
  specialized new-development workflows.
- Cities outside Americana, Santa Bárbara d'Oeste, and Nova Odessa during the
  pilot.
- CRM, lead management, sales pipeline, tour scheduling, contracts, offers, and
  transaction management.
- WhatsApp or email delivery from HouseSearch; the broker shares generated
  content through external tools.
- Buyer contact storage, client profiles, documents, or identity matching.
- School, crime, demographic, protected-characteristic, "safe," or
  "family-friendly" neighborhood scoring.
- Broker-managed sources, informal-contact inventory, manual property entry, or
  unrestricted web search.
- Republishing full listings or operating as a listing marketplace.
- Automated checkout, recurring card charging, invoice generation, or tax
  document issuance.
- Native mobile applications.
- Autonomous requirement relaxation, AI-based deduplication, invented listing
  enrichment, or automatic learning from individual feedback.

## Architecture Decision Records

- [ADR-001: Broker-Controlled Evidence-Backed Shortlists](adrs/adr-001.md) — Use
  top-ranked exact matches and require explicit broker approval before a
  disclosed near-match enters the shortlist.
- [ADR-002: Confirmed Criteria and Supported Pilot Inventory](adrs/adr-002.md) —
  Let brokers confirm proposed hard and soft classifications within a precise
  objective-criteria, geographic, and property-type boundary.
- [ADR-003: Invite-Only Pilot and Transparent Usage Charging](adrs/adr-003.md) —
  Use controlled onboarding, explicit overage consent, a seven-day refinement
  window, and credits only for zero-result technical failures.

## Open Questions

None. All load-bearing product decisions identified during MVP research and
requirements clarification are resolved in this PRD and its ADRs.
