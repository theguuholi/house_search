---
name: flop-pagination-standards
description: Use when creating or materially changing HouseSearch Flop schemas, filtered or sorted context lists, URL-driven pagination, sortable tables, pagination components, or their tests.
---

# Flop Pagination Standards

## Core contract

Treat the URL as list state, the context as query owner, the schema as the
allowlist, and shared function components as stateless renderers.

## Required workflow

1. Read `.agents/rules/flop-pagination.md` and the applicable Ecto, LiveView,
   and LiveView testing standards.
2. Derive `Flop.Schema` with explicit `filterable`, `sortable`, pagination,
   limit, and deterministic default-order options.
3. Accept URL parameter maps at the context boundary. Apply friendly domain
   filters such as `q` to the base query, remove them before Flop validation,
   and call `Flop.validate_and_run/3` with `for: Schema`, the project Repo,
   and `replace_invalid_params: true`.
4. Load route-backed list state only in `handle_params/3`; patch the URL for
   search, sort, and pagination and remove `page` when search changes.
5. Render through the shared stateless table and pagination components.
6. Add focused context, component, and LiveView RED/GREEN coverage.

## Quick reference

| Layer | Owns | Must not own |
|---|---|---|
| Schema | allowlists, limits, pagination type, stable default order | public URL parsing |
| Context | friendly filters, validation, query, Repo execution | socket state |
| LiveView | URL patching, forms, assigns, mutations | Ecto queries or offsets |
| Component | links, icons, semantic and ARIA markup | fetching, parsing, events |

## Common mistakes

- Do not derive Flop with broad field lists or convert client strings to atoms.
- Do not keep `q` in Flop params when the public contract is a friendly filter.
- Do not load URL state in `mount/3` or reload lists directly from events.
- Do not make sorting or pagination stateful components.
- Do not omit a unique final order field when preceding fields can tie.
- Do not expose interactive disabled controls or icon-only sort state.

## Completion gate

Confirm invalid inputs fall back safely, links preserve unrelated query
parameters, search resets the page, shared components remain plain-table
compatible, and focused plus project verification passes.
