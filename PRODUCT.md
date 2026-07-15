# Business Definition — HouseSearch

**Date:** July 15, 2026

**Status:** initial proposal for pilot validation

**Initial market:** independent real estate brokers in Americana, São Paulo, and
the surrounding region

## Summary

HouseSearch reduces the manual work involved in searching for properties across
multiple portals, real estate agency websites, and scattered contacts. The
broker describes what the client is looking for, confirms the criteria
interpreted by the assistant, and receives three justified options with the
source, direct link, and date of the latest verification.

The MVP promise is to deliver **three useful options within ten minutes**. The
product does not replace the broker: it organizes the research and supplies
evidence so the broker can decide what to present to the client.

## Problem

A real estate broker receives requests containing price, neighborhood, property
type, bedrooms, and subjective preferences. To find suitable options, the broker
repeats filters across several websites, compares incomplete listings, removes
duplicates, and tries to remember which pages have already been checked. This
process is time-consuming, difficult to audit, and hard to repeat consistently.

## Initial customer

The first paying customer is the **independent real estate broker** serving home
buyers in the Americana region. This is a strong initial audience because the
broker experiences the problem frequently, can decide independently which work
tools to adopt, and can quickly assess whether a shortlist is useful.

End buyers, real estate agency teams, rentals, property acquisition, and a full
CRM are outside the first pilot.

## Job to be done

> When a client tells me what kind of property they want, I want to search
> trusted sources at once and receive the best options with clear explanations,
> so I can respond quickly without spending hours researching manually.

## Value proposition

- One conversation replaces repeated filtering across several websites.
- Each recommendation explains why it matches and which criteria it falls short
  on.
- Results include the source, direct link, and time of the latest verification.
- Research continues in the background without blocking the application.
- The broker retains the final decision and can refine the search case for seven
  days.

## Primary journey

1. The broker describes the client's request in natural language.
2. The assistant extracts structured criteria, asks no more than one clarifying
   question at a time, and requests confirmation.
3. Confirmation creates a search case and consumes one included unit.
4. The application shows results from the local index and refreshes stale
   sources in the background.
5. Deterministic rules filter, deduplicate, and score the listings.
6. The assistant explains the top three using only verified data.
7. The broker marks options as useful or unsuitable and may refine the same
   search case for seven days without consuming another unit.

## Revenue model

The model is a **monthly subscription with included search cases and paid
overages**. One unit represents a confirmed client request, including refinements
made during the following seven days. Messages, filter changes, and new
shortlist versions within that window do not consume additional units.

### Initial pricing experiment

- Assisted trial: 14 days and up to 10 search cases, with no card required.
- Founding Plan: BRL 149 per month, including 30 search cases.
- Overage: BRL 5 per additional search case.
- Pilot billing: monthly review of the usage ledger and manual payment;
  automated checkout is outside the MVP.

This price is a hypothesis to test through interviews and actual sales, not a
market conclusion. As a perceived ceiling reference, broader real estate
platforms currently advertise plans starting at BRL 229 per month, although
they include CRM, website, and management capabilities beyond property search.
The comparison provides willingness-to-pay context only and does not imply
product equivalence: [Jetimob plans](https://www.jetimob.com/planos).

The price will be retained only if:

- the average variable cost stays below 20% of revenue per search case;
- at least three of the five pilot brokers agree to pay;
- most participants report time savings worth more than the monthly fee.

## Pilot

The pilot will involve five brokers and at least fifty real search cases. A
shortlist is useful when the broker confirms that all three options can be
presented to the client, even if one includes clearly disclosed caveats.

### Primary metric

At least 70% of completed search cases must deliver three useful options within
ten minutes after criteria confirmation.

### Supporting metrics

- time to first result;
- time to first complete shortlist;
- percentage of listings with valid price, location, and link;
- percentage of queried sources that complete successfully;
- duplicates removed per search case;
- options forwarded to the client;
- collection and LLM cost per search case;
- sources contributing the most useful options.

## MVP boundaries

Included:

- residential properties for sale in Americana and the surrounding region;
- authenticated independent real estate brokers;
- sources registered only by an administrator;
- hybrid search, Top 3 shortlist, and seven-day refinement window;
- usage ledger for manual billing;
- simple usefulness feedback on recommendations.

Not included:

- rentals, short-term rentals, and commercial properties;
- end buyers as users;
- CRM, sales pipeline, or contract management;
- unrestricted source registration by brokers;
- automated checkout and tax document issuance;
- native mobile application;
- publishing or republishing property listings.

## Business risks

| Risk | Validation or mitigation |
|---|---|
| Sources block or prohibit collection | Activate a source only after reviewing its terms, robots.txt, and official integration alternatives |
| Stale listings undermine trust | Show the latest verification, validate the link, and remove listings after repeated failures |
| The three results are not genuinely useful | Collect feedback per option and review ranking weights weekly during the pilot |
| The LLM invents attributes | Require field-level evidence and restrict AI to explaining data supplied by the system |
| Brokers will not pay BRL 149 | Make a paid offer during the pilot instead of relying on opinion surveys |
| Variable costs rise with usage | Record cost per job and LLM call, enforce limits, and prefer deterministic extraction |

## Continuation criteria

The product advances to a commercial version only after meeting all of the
following conditions:

1. fifty real search cases completed;
2. 70% delivering three useful options within ten minutes;
3. at least three brokers willing to pay for the Founding Plan;
4. variable cost below 20% of projected revenue;
5. at least three stable and authorized sources contributing results.

If these criteria are not met, the priority is to improve data coverage and
quality before adding more AI agents, regions, or features.
