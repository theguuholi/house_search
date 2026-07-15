# HouseSearch

HouseSearch is a property research assistant for independent real estate brokers.
It turns a client's request into an explained shortlist of three properties by
combining a local index with asynchronous updates from approved sources.

## Project status

The project is in the **Spec-Driven Development** phase. The business definition
and initial architecture must be reviewed before creating the implementation
plan or making functional code changes.

## Core documents

- [PRODUCT.md](PRODUCT.md): problem, audience, value proposition, pricing, and
  validation criteria.
- [ARCHITECTURE.md](ARCHITECTURE.md): initial SDD, module boundaries, data model,
  hybrid flow, AI, jobs, security, and testing strategy.

## Technical direction

- Elixir, Phoenix, and LiveView for the modular monolith and real-time
  experience.
- PostgreSQL/Ecto as the source of truth.
- Oban for collection, refreshes, retries, and asynchronous recomputation.
- Sagents to interpret requests, confirm criteria, and explain the shortlist.
- Explicit adapters for portals and real estate agency websites registered by
  an administrator.

## Local development

The project still contains the original Phoenix scaffold. Runtime commands and
final dependencies will be updated in the implementation plan after the SDD is
approved.
