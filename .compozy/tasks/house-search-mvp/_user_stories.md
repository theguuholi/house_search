# User Stories: HouseSearch MVP

Canonical behavior catalog for the HouseSearch MVP. Companion to `_prd.md`;
consumed by `_techspec.md` for component mapping and `_tests.md` for its coverage
matrix.

## Personas

- **Independent broker** — an invited professional serving residential buyers
  in the pilot region who needs to research, assess, and share suitable
  properties quickly while retaining final judgment.
- **Administrator** — the pilot operator who controls broker access, approved
  sources, source coverage, compliance records, allowances, and manual billing.
- **Client recipient** — the broker's buyer, who does not sign in to HouseSearch
  but receives a broker-approved summary containing verified recommendations.

## Story Index

| ID | Feature Area | Persona | Story |
| --- | --- | --- | --- |
| US-001 | Pilot access | Administrator | Invite, activate, suspend, and restore a pilot broker |
| US-002 | Source governance | Administrator | Approve and control searchable listing sources |
| US-003 | Request intake | Independent broker | Describe a buyer request conversationally |
| US-004 | Criteria confirmation | Independent broker | Confirm hard requirements and preferences before searching |
| US-005 | Usage authorization | Independent broker | Understand and approve the unit or overage consumed by a case |
| US-006 | Property research | Independent broker | Receive progressive verified results despite partial failures |
| US-007 | Shortlist control | Independent broker | Review exact matches and explicitly approve near-matches |
| US-008 | Recommendation evidence | Independent broker | Understand and verify every recommendation |
| US-009 | Client sharing | Independent broker | Generate a client-ready summary of an approved shortlist |
| US-010 | Recommendation feedback | Independent broker | Reject unsuitable options and receive controlled replacements |
| US-011 | Case refinement | Independent broker | Refine a confirmed request for seven days without another unit |
| US-012 | Usage administration | Administrator | Audit allowances, overages, and technical-failure credits |

## Pilot Access

### US-001: Manage pilot broker access

**As an** administrator, **I want** to invite and control broker access, **so
that** only selected pilot participants can use HouseSearch.

Acceptance criteria:

- AC-1: Given an email not attached to an existing user, when the administrator
  sends an invitation, then the invitee receives a single-use path to establish
  access.
- AC-2: Given a valid invitation, when the broker completes activation, then the
  broker can sign in and sees the trial allowance and expiry.
- AC-3: Given an active broker, when the administrator suspends access, then new
  sessions and billable actions are blocked while existing case records remain.
- AC-4: Given a suspended broker, when the administrator restores access, then
  the broker regains access to permitted existing cases and the current
  allowance state.

Edge cases:

- EC-1: Invalid or malformed email → the invitation is rejected with a specific
  correction message.
- EC-2: Missing broker name or email → no invitation is created.
- EC-3: Pilot participant limit is reached → the administrator sees the limit
  and must explicitly expand pilot capacity before inviting another broker.
- EC-4: A non-administrator attempts access management → the action is denied
  without revealing account details.
- EC-5: Two administrators invite the same email concurrently → one pending
  invitation exists and both see its current state.
- EC-6: Activation is interrupted → the unused valid invitation can be resumed
  without creating a second account.
- EC-7: An accepted invitation is replayed → the broker is directed to sign in;
  no duplicate membership is created.
- EC-8: A broker opens an activation path after signing in as another user → the
  user must sign out or use the matching identity before continuing.
- EC-9: An expired, revoked, or already accepted invitation is used → activation
  is blocked with an accurate state-specific message.
- EC-10: The participant list grows far beyond the pilot size → access controls,
  search, and pagination remain usable without exposing other brokers' cases.

## Source Governance

### US-002: Govern approved sources

**As an** administrator, **I want** to register, review, activate, degrade, and
deactivate listing sources by pilot city, **so that** brokers search only
authorized and traceable inventory.

Acceptance criteria:

- AC-1: Given a proposed source, when the administrator records its identity,
  covered cities, permitted retrieval method, terms review, robots review, rate
  limits, and review date, then it remains inactive until explicitly activated.
- AC-2: Given a fully reviewed source for at least one pilot city, when the
  administrator activates it, then its verified listings may contribute to new
  and open cases in those cities.
- AC-3: Given an active source, when it is deactivated or degraded, then new
  on-demand research no longer relies on it and brokers see an accurate source
  availability state.
- AC-4: Given an official API or feed, when the source is reviewed, then an
  unapproved page-collection method cannot be selected instead.

Edge cases:

- EC-1: Invalid source address, unsupported protocol, or unapproved redirect
  host → activation is rejected with the invalid field identified.
- EC-2: Missing terms or robots review → the source can be saved as a draft but
  cannot be activated.
- EC-3: An administrator exceeds a source's configured request limit → further
  collection waits and the source is not falsely marked successful.
- EC-4: A broker attempts to add or activate a source → the action is denied and
  no configuration is disclosed.
- EC-5: Two administrators change the same source concurrently → the later user
  sees that the source changed and must review before overwriting it.
- EC-6: Activation is interrupted after review → the source remains in one
  visible, recoverable state and is never partly active.
- EC-7: The same source and city are submitted repeatedly → the existing record
  is reused or a clear duplicate warning is shown.
- EC-8: Activation is attempted before required reviews → the prerequisite is
  displayed and the state does not advance.
- EC-9: A source is deactivated while cases are searching → persisted evidence
  remains visible, new retrieval stops, and affected cases continue with other
  sources.
- EC-10: A source returns 100 times its normal inventory → collection remains
  bounded and brokers can continue using already verified results.

## Request Intake

### US-003: Describe a buyer request

**As an** independent broker, **I want** to describe a buyer's desired property
in natural language, **so that** I do not repeat filters across multiple sites.

Acceptance criteria:

- AC-1: Given an authenticated active broker, when the broker describes a
  residential purchase in the pilot region, then HouseSearch proposes supported
  structured criteria without opening a billable case.
- AC-2: Given ambiguous or missing load-bearing information, when the request is
  interpreted, then the assistant asks one clarification at a time.
- AC-3: Given a subjective phrase such as "safe" or "family-friendly," when it
  cannot be supported by listing evidence, then the assistant asks for an
  objective buyer-confirmed criterion and does not infer demographics, crime,
  schools, or protected characteristics.
- AC-4: Given a request for unsupported inventory, when it is interpreted, then
  HouseSearch explains the pilot boundary and preserves the draft for editing.

Edge cases:

- EC-1: Hostile, unparseable, or non-property input → no criteria are invented;
  the broker receives a safe request to restate the need.
- EC-2: Blank request → the broker is prompted to describe the property before
  continuing.
- EC-3: Input exceeds the supported length → it is rejected or safely truncated
  with the limit shown before any information is lost.
- EC-4: An unauthenticated or suspended broker submits a request → no draft is
  processed and access guidance is shown.
- EC-5: Two messages are submitted concurrently → they appear once in a stable
  order and cannot open duplicate drafts.
- EC-6: The connection drops after submission → the broker sees the saved draft
  and interpretation state after reconnecting.
- EC-7: The same message is retried → it does not duplicate criteria or consume
  usage.
- EC-8: The broker tries to confirm before clarification finishes → confirmation
  remains unavailable and the unresolved item is shown.
- EC-9: A draft references rentals, commercial property, land, rural property,
  or a city outside the pilot → the unsupported parts are identified and the
  draft remains editable.
- EC-10: A request contains many preferences → all supported criteria remain
  reviewable, and any display summarization does not hide what will be confirmed.

## Criteria Confirmation

### US-004: Confirm interpreted criteria

**As an** independent broker, **I want** to review and confirm the interpreted
criteria, **so that** HouseSearch searches the request I actually intend.

Acceptance criteria:

- AC-1: Given interpreted criteria, when review begins, then every criterion is
  visibly classified as a proposed hard requirement or preference and can be
  edited by the broker.
- AC-2: Given supported criteria, when the broker confirms them, then the exact
  version is preserved and used for eligibility and ranking.
- AC-3: Given a missing optional listing field, when matching runs, then the
  field is treated as unknown and never as satisfying a requirement or
  preference.
- AC-4: Given a request containing price, city, neighborhood, property type,
  bedrooms, bathrooms, parking, floor area, or evidence-backed free-form
  preferences, when confirmed, then each supported value remains visible in the
  confirmed summary.

Edge cases:

- EC-1: Invalid ranges, negative values, or contradictory criteria →
  confirmation is blocked and each conflict is explained.
- EC-2: No hard requirements are present → confirmation is allowed only after
  the broker acknowledges that all supported inventory may be eligible.
- EC-3: The confirmed criteria exceed supported value or selection limits → the
  broker must reduce them before continuing.
- EC-4: Another broker opens the draft URL → access is denied without revealing
  the criteria.
- EC-5: Criteria change in one session while another session confirms stale
  values → the stale session must reload and review the current version.
- EC-6: The connection drops during confirmation → the broker sees whether
  confirmation succeeded before taking another billable action.
- EC-7: Confirmation is submitted twice → one criteria version and at most one
  case-opening attempt result.
- EC-8: Confirmation is attempted before the classification review → the review
  is shown and no case opens.
- EC-9: The draft is discarded or the account is suspended before confirmation
  → confirmation is unavailable and no unit is consumed.
- EC-10: A criteria set contains a large number of supported preferences → the
  broker can inspect all of them and the confirmed version remains complete.

## Usage Authorization

### US-005: Authorize case usage

**As an** independent broker, **I want** to know whether a search consumes an
included unit or paid overage, **so that** no charge surprises me.

Acceptance criteria:

- AC-1: Given available included allowance, when the broker confirms criteria,
  then HouseSearch states that one included unit will be consumed before the
  case opens.
- AC-2: Given an exhausted paid-plan allowance, when the broker confirms
  criteria, then the case opens only after explicit acceptance of a BRL 5
  overage.
- AC-3: Given an exhausted trial allowance or expired trial, when the broker
  tries to open a case, then activation of the paid plan is required.
- AC-4: Given successful authorization, when the case opens, then exactly one
  unit is associated with that confirmed request.

Edge cases:

- EC-1: Missing or invalid plan state → case opening is blocked and the broker
  receives administrator-contact guidance.
- EC-2: Allowance information is unavailable → no overage is assumed and no case
  opens until the cost can be shown.
- EC-3: Monthly allowance is exhausted between confirmation and opening → the
  broker sees the overage choice before any chargeable case is created.
- EC-4: A suspended broker accepts an overage → the action is denied and no usage
  event is created.
- EC-5: Two sessions try to consume the last included unit → only one uses it;
  the other receives the current overage choice.
- EC-6: The connection drops after overage acceptance → reconnecting reveals
  whether the case opened and does not ask for duplicate acceptance.
- EC-7: Confirmation or overage acceptance is retried → exactly one case and one
  usage event exist.
- EC-8: Overage acceptance is attempted before criteria confirmation → no case
  opens and the missing prerequisite is shown.
- EC-9: The plan expires while the authorization screen is open → the broker
  must review the updated plan state before proceeding.
- EC-10: Usage volume grows beyond the pilot norm → the broker still sees an
  accurate allowance and itemized case history.

## Property Research

### US-006: Receive progressive verified results

**As an** independent broker, **I want** to see verified results as research
progresses, **so that** I can start assessing properties without waiting for
every source.

Acceptance criteria:

- AC-1: Given an opened case, when verified local results exist, then they are
  displayed while approved stale sources refresh in the background.
- AC-2: Given new verified results, when the case is open, then the visible
  candidates and case state update without losing broker actions.
- AC-3: Given one or more source failures, when other sources return verified
  properties, then research continues and the unavailable sources are disclosed
  to the broker.
- AC-4: Given the ten-minute research deadline, when it expires, then the case
  finishes with the best verified exact and separate near-match results
  available and an accurate complete, partial, empty, or failed state.

Edge cases:

- EC-1: A source returns invalid links, prices, locations, or malformed records
  → those records are excluded and the source outcome is reported accurately.
- EC-2: No approved source covers the confirmed city → the case ends without
  fabricated results and identifies the coverage gap.
- EC-3: A source reaches its retrieval limit → existing verified results remain
  available and the delayed source is shown as incomplete.
- EC-4: Another broker attempts to view the case → access is denied without
  revealing criteria, results, or source details.
- EC-5: Multiple sources return the same property concurrently → the broker sees
  one distinct candidate with preserved source evidence.
- EC-6: The browser disconnects or the service restarts during research → the
  broker can resume from persisted progress and receives subsequent updates.
- EC-7: A completed retrieval is retried → listings and visible candidates are
  not duplicated.
- EC-8: A result update arrives before the case-opening view loads → the current
  persisted state is shown when the broker opens or reconnects.
- EC-9: A listing becomes unavailable during an open case → it is marked
  unavailable, removed from eligibility, and the case is recomputed.
- EC-10: Candidate volume is 100 times normal → the broker receives bounded,
  responsive result views ordered by the confirmed ranking rules.

## Shortlist Control

### US-007: Control exact and near-match shortlist options

**As an** independent broker, **I want** exact matches separated from
near-matches, **so that** no client requirement is relaxed without my approval.

Acceptance criteria:

- AC-1: Given at least three exact matches, when ranking completes, then the
  shortlist contains the three highest-ranked distinct properties.
- AC-2: Given fewer than three exact matches, when research completes, then
  exact matches occupy available shortlist positions and near-matches remain in
  a separate section with every failed hard requirement stated.
- AC-3: Given a near-match, when the broker approves its disclosed compromise,
  then it may fill an open shortlist position and retains its near-match label.
- AC-4: Given an unapproved near-match, when client-ready content is generated,
  then that property is excluded.

Edge cases:

- EC-1: A near-match lacks enough data to state the compromise → it cannot be
  approved into the shortlist.
- EC-2: No exact or near-matches exist → the broker sees an empty outcome and
  guidance to refine, without invented options.
- EC-3: Many near-matches exist → only a bounded ranked set is shown initially,
  with controlled access to additional candidates.
- EC-4: A broker tries to approve a property from another account's case → the
  action is denied.
- EC-5: Two sessions approve different near-matches for the final position → the
  later session must review the current shortlist before replacing it.
- EC-6: Approval is interrupted → the broker sees whether the property entered
  the shortlist before retrying.
- EC-7: The same approval is submitted twice → the property occupies one
  position and one approval is recorded.
- EC-8: A near-match is approved before the exact-match search settles → it stays
  labeled and may be displaced only according to a visible broker action, not
  silently.
- EC-9: An approved property becomes unavailable → it leaves the active
  shortlist and replacement follows the same exact-before-near rules.
- EC-10: Hundreds of eligible candidates tie → deterministic ordering produces
  the same three distinct properties for the same criteria and data state.

## Recommendation Evidence

### US-008: Verify recommendation reasoning

**As an** independent broker, **I want** every recommendation tied to verified
facts, **so that** I can judge it before presenting it to a client.

Acceptance criteria:

- AC-1: Given a recommended property, when the broker inspects it, then the
  broker sees source, direct link, latest verification time, match reasons,
  unknown fields, and disclosed compromises.
- AC-2: Given an explanation, when it names a property attribute, then that
  attribute exists in the verified listing evidence.
- AC-3: Given unavailable generated narrative, when deterministic evidence and
  ranking exist, then the broker still sees factual reasons and can continue.
- AC-4: Given multiple listings for one property, when displayed, then the
  recommendation identifies the selected source link and preserves alternate
  provenance where relevant.

Edge cases:

- EC-1: Evidence contains an invalid or unsafe link → the link is not offered and
  the property cannot qualify for recommendation.
- EC-2: An optional fact is missing → it appears as unknown and is omitted from
  positive match claims.
- EC-3: Evidence or explanation exceeds display limits → the broker can access
  the complete factual record without silent loss of decisive caveats.
- EC-4: A user without case access requests evidence → access is denied.
- EC-5: Evidence changes while the broker is reading → freshness and current
  availability update, and stale claims are not presented as current.
- EC-6: Explanation generation is interrupted → deterministic reasons remain
  visible and retry does not block the shortlist.
- EC-7: Explanation is regenerated → facts remain bounded to the same verified
  evidence and do not create duplicate recommendations.
- EC-8: A deep link targets evidence before recommendation creation → the broker
  sees a pending or unavailable state, not a broken factual claim.
- EC-9: The source removes the property → the recommendation is visibly
  unavailable and cannot enter new client-ready summaries.
- EC-10: A property has extensive history and evidence → the default view stays
  readable while the latest facts and decisive provenance remain accessible.

## Client Sharing

### US-009: Generate a client-ready summary

**As an** independent broker, **I want** a concise summary of my approved
shortlist, **so that** I can share it using my existing communication tools.

Acceptance criteria:

- AC-1: Given a broker-approved shortlist, when a summary is generated, then it
  contains key facts, match reasons, disclosed compromises, source links, and
  latest verification times for approved available properties.
- AC-2: Given internal ranking details or source failures, when the summary is
  generated, then numeric scores, score breakdowns, operational diagnostics,
  and other broker-only information are excluded.
- AC-3: Given the generated summary, when the broker copies or shares it, then
  HouseSearch does not require or store the client's name, phone number, email,
  or documents.
- AC-4: Given a shortlist change, when the broker requests a new summary, then
  the new content reflects only the currently approved available options.

Edge cases:

- EC-1: A source link becomes invalid before generation → the affected property
  is excluded or clearly blocked from sharing until reverified.
- EC-2: The shortlist is empty → generation is unavailable with a clear reason.
- EC-3: The summary exceeds a destination's common copy length → the broker gets
  a concise complete version without losing links or compromises.
- EC-4: Another broker requests the summary → access is denied.
- EC-5: Two sessions generate while the shortlist changes → each summary shows
  its generation time, and the broker is warned before copying a stale version.
- EC-6: Generation is interrupted → no incomplete summary is presented as ready;
  the broker can retry.
- EC-7: Generation is repeated without changes → content remains consistent and
  does not create client-contact records.
- EC-8: Generation is attempted before near-match approval → unapproved
  near-matches are excluded and the prerequisite is stated.
- EC-9: A previously shared property becomes unavailable → future summaries
  exclude it and the broker sees the changed shortlist state.
- EC-10: A case has many historical shortlist versions → generation uses the
  current approved version and remains responsive.

## Recommendation Feedback

### US-010: Reject and replace an unsuitable option

**As an** independent broker, **I want** to mark recommendations useful or
unsuitable, **so that** the current shortlist improves and pilot learning is
grounded in explicit feedback.

Acceptance criteria:

- AC-1: Given an available recommendation, when the broker marks it useful,
  then the verdict is recorded in one action without requiring a reason.
- AC-2: Given an available recommendation, when the broker marks it unsuitable,
  then a predefined reason is required and an optional note is accepted.
- AC-3: Given an unsuitable shortlist property, when the verdict is saved, then
  it is removed and the next exact match fills the position automatically.
- AC-4: Given no remaining exact match, when replacement is needed, then the
  next near-match is proposed separately and requires approval before entering
  the shortlist.

Edge cases:

- EC-1: An unknown verdict or invalid reason is submitted → feedback is rejected
  and the current shortlist remains unchanged.
- EC-2: The required unsuitable reason is missing → the broker is prompted to
  select one; no replacement occurs yet.
- EC-3: The optional note exceeds its limit → the broker sees the limit and can
  edit without losing the selected reason.
- EC-4: Another broker submits feedback → access is denied.
- EC-5: Two sessions give conflicting verdicts → the later session must review
  the current verdict and shortlist before changing it.
- EC-6: The connection drops during rejection → reconnecting shows whether the
  verdict and replacement succeeded.
- EC-7: The same feedback is retried → one current verdict exists and the option
  is replaced at most once.
- EC-8: Feedback is submitted for a property before it enters the shortlist → it
  may be recorded on the candidate but cannot trigger an out-of-order shortlist
  replacement.
- EC-9: Feedback targets an unavailable or already removed recommendation → the
  broker sees its current state and no second replacement occurs.
- EC-10: Many candidates have already been rejected → HouseSearch continues in
  rank order, never cycles rejected properties back into the current version,
  and reports when no replacement remains.

## Case Refinement

### US-011: Refine a case within seven days

**As an** independent broker, **I want** to revise an existing buyer request for
seven days, **so that** normal buyer feedback does not create repeated charges.

Acceptance criteria:

- AC-1: Given a confirmed case within seven days of its original confirmation,
  when the broker explicitly chooses to refine it, then any supported criteria
  may be changed and reconfirmed without consuming another unit.
- AC-2: Given reconfirmed criteria, when refinement begins, then a new criteria
  and shortlist version is visible while prior versions remain auditable.
- AC-3: Given an expired case, when the broker requests a refinement, then
  HouseSearch requires a new billable case and shows the cost before opening it.
- AC-4: Given an active refinement, when results update, then exact, near-match,
  evidence, feedback, and sharing rules apply identically to the new version.

Edge cases:

- EC-1: Refined criteria contain invalid values or unsupported inventory →
  reconfirmation is blocked without affecting the current confirmed version.
- EC-2: A case has no prior confirmed criteria → it cannot enter refinement and
  the broker returns to request intake.
- EC-3: The seven-day boundary passes while the edit screen is open → the broker
  must approve a new billable case before confirming changes.
- EC-4: Another broker attempts refinement → access is denied.
- EC-5: Two sessions refine the same version concurrently → the second must
  reconcile with the newly confirmed version before proceeding.
- EC-6: Refinement is interrupted before confirmation → the last confirmed
  version remains active and the draft can be resumed while eligible.
- EC-7: Reconfirmation is retried → one new criteria version is created and no
  usage unit is consumed.
- EC-8: A broker attempts sharing from an unconfirmed refinement draft → the
  last approved shortlist remains the shareable version.
- EC-9: The account is suspended or the case becomes expired during refinement
  → confirmation is blocked with the accurate reason.
- EC-10: A case has many refinements → the current version remains clear and
  usable while prior versions stay accessible for audit without cluttering the
  primary flow.

## Usage Administration

### US-012: Audit usage, overages, and credits

**As an** administrator, **I want** an auditable usage ledger, **so that** I can
reconcile pilot billing and correct complete technical failures fairly.

Acceptance criteria:

- AC-1: Given a confirmed new case, when it opens, then the administrator sees
  one usage unit attributed to the broker and case.
- AC-2: Given an accepted paid overage, when the case opens, then the ledger
  records the BRL 5 overage consent and amount.
- AC-3: Given platform or approved-source failures that leave a case with zero
  verified properties, when the case reaches its terminal state, then its unit
  is restored automatically and the reason is visible.
- AC-4: Given a legitimate empty result after successful research or any partial
  result containing verified properties, when the case ends, then its unit
  remains consumed.

Edge cases:

- EC-1: A usage event has invalid units, amount, or case attribution → it is not
  included in billing and is flagged for administrator review.
- EC-2: Usage history is empty → the administrator sees zero totals and no
  fabricated entries.
- EC-3: Allowance, trial, or billing-period boundaries are reached → totals are
  assigned to the correct period and the broker sees the same remaining count.
- EC-4: A broker or unauthorized administrator requests another account's
  ledger → access is denied.
- EC-5: Case completion and credit evaluation occur concurrently → at most one
  final credit decision affects the balance.
- EC-6: Credit evaluation is interrupted → it resumes to a final auditable state
  without leaving the balance ambiguous.
- EC-7: Case opening, failure reporting, or credit evaluation is replayed → each
  business event affects allowance exactly once.
- EC-8: A credit is requested before a case reaches a terminal zero-result state
  → the decision waits and no premature balance change occurs.
- EC-9: A previously credited case later receives a verified result → the
  administrator sees the conflict for review; the balance is not changed
  silently.
- EC-10: Ledger volume is 100 times pilot expectations → totals, itemized history,
  and manual reconciliation remain accurate and navigable.
