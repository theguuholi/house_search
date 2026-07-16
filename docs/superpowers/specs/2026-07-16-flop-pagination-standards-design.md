# Flop Pagination and Sorting Standards Design

## Summary

HouseSearch will standardize list filtering, sorting, and pagination on Flop and
Flop Phoenix. The broker listing will become the reference implementation. URL
parameters will be the source of truth, LiveViews will load list data through
`handle_params/3`, contexts will validate and execute Flop queries, and reusable
function components will remain stateless.

Scrivener is not selected because it only addresses page pagination and is in
low-maintenance mode. Flop provides validated Ecto filtering, ordering,
pagination metadata, Phoenix URL integration, sortable tables, and pagination
components.

## Dependencies

Add compatible direct dependencies on `flop` and `flop_phoenix`. Application
code uses Flop query APIs directly and `HouseSearchWeb.CoreComponents` uses
Flop Phoenix components directly, so both packages are explicit project
dependencies.

The selected versions must remain compatible with the locked HouseSearch
baseline of Phoenix 1.7.24, LiveView 1.0.18, Ecto 3.10+, and Elixir 1.14.

## Schema Contract

`HouseSearch.Accounts.Invitation` will derive `Flop.Schema` with an explicit
allowlist:

- Page-based pagination only.
- Default page size of 25 and maximum page size of 100.
- User-facing sortable fields: `name`, `email`, `status`, and `inserted_at`.
- `id` is also present in the schema sortable allowlist because Flop requires
  every `default_order` field to be sortable. It is reserved for deterministic
  tie-breaking and is not exposed as a table column or sort control.
- A deterministic default order that preserves the current behavior and adds a
  stable tie-breaker: `inserted_at` descending, `email` ascending, then `id`
  ascending.

All future Flop-enabled schemas must declare filterable and sortable fields
explicitly. URL input must never be converted into field atoms outside Flop's
validated schema allowlist. Every paginated order must be deterministic; add a
unique tie-breaker when the visible order fields do not guarantee stability.

## Context Contract

`HouseSearch.Accounts.list_brokers/1` will accept a URL parameter map rather
than manually parsed keyword options. It will apply the friendly `q` value as a
domain-specific name/email condition on the base query, remove `q` from the
parameters passed to Flop, and then use validated Flop query APIs. It returns
`{invitations, %Flop.Meta{}}`.

Keeping `q` outside `Flop.Meta` prevents Flop Phoenix from adding nested
`filters[...]` parameters alongside the public `q` parameter. Pages that choose
to expose native Flop filters may define explicit schema filter allowlists and
use Flop filter forms instead.

The context owns query construction, filtering, validation, ordering,
pagination, and Repo execution. LiveViews and components must not build Ecto
queries, parse integers, calculate offsets, or receive a Repo dependency.

Invalid pagination and sorting input will be replaced with schema defaults so
malformed public URLs render a valid list instead of crashing. This replacement
is limited by the schema allowlist and does not permit unknown sort or filter
fields.

## LiveView and URL Flow

The broker LiveView will use this lifecycle:

1. `mount/3` initializes authorization state and forms only.
2. `handle_params/3` passes URL parameters to `Accounts.list_brokers/1` and
   assigns `invitations`, `meta`, `q`, and the component path.
3. Search events trim the submitted `q` value and call `push_patch/2`. A changed
   search removes the current page so results restart on page one.
4. Sort and pagination controls patch the URL. `handle_params/3` performs every
   resulting reload.
5. Successful invite and revoke operations preserve the current search and sort
   URL and refresh the list through the same URL-driven loading path.

The public search parameter remains `q`. The Flop path builder merges page and
sort parameters into a verified route that already contains `q`. A bookmark,
refresh, browser back/forward action, or shared URL must reproduce the same
list state.

## Stateless Component Contract

### Table

Refactor the existing `HouseSearchWeb.CoreComponents.table/1`; do not introduce
a parallel sortable-table component.

The existing `id`, `rows`, `row_id`, `row_click`, `row_item`, column slots, and
action slots remain supported. Add optional `meta` and `path` attributes and a
`field` attribute on column slots. When Flop metadata, a path, and a sortable
field are present, sorting is delegated to Flop Phoenix. Without those inputs,
the table retains its plain, non-sortable behavior.

Sortable headers use Heroicons for ascending, descending, and unsorted states.
The header remains a real link, communicates its accessible name and current
sort direction, and does not rely on the icon alone.

### Pagination

Add `HouseSearchWeb.CoreComponents.pagination/1` as an application-styled
wrapper around Flop Phoenix. Its required inputs are `meta` and `path`; optional
inputs may cover a distinct accessible label and LiveComponent target without
introducing component-owned state.

The component renders previous, next, page, current-page, and ellipsis states
from `Flop.Meta`. Disabled controls are not interactive. The current page is
exposed with `aria-current="page"`, and the navigation landmark has an
accessible label.

Both components are pure renderers. They do not fetch data, parse URL values,
calculate offsets, or handle pagination events.

## Standards Package

Add `.agents/rules/flop-pagination.md` as the concise project gate for Flop
schema configuration, context boundaries, URL-driven LiveViews, stateless
components, accessibility, and tests.

Add one local `flop-pagination-standards` skill covering:

- Schema allowlists, pagination limits, friendly versus native filters, and
  deterministic ordering.
- Context parameter normalization and validated Flop execution.
- `mount/3` versus `handle_params/3` responsibilities.
- Search-to-URL patching and page reset behavior.
- Reuse of the application table and pagination wrappers.
- Testing expectations and common failure modes.

Update `AGENTS.md` so changes involving Flop, list filtering, sorting, or
pagination require this skill. Existing LiveView, LiveView testing, and Ecto
schema rules and skills will link to the new standard where relevant, without
duplicating its full content.

The new skill will be developed with a baseline scenario before authoring and
the same scenario after authoring. Validation must confirm that the skill routes
a representative broker-list request toward schema allowlists, context-owned
queries, `handle_params/3`, and stateless components.

## Testing

Production behavior will be implemented test-first.

### Context and schema coverage

- Default page size and maximum page-size enforcement.
- Stable default ordering.
- Friendly `q` matching invitation name or email.
- Explicit ascending and descending sorts for allowed fields.
- Requested pages return the correct records and metadata.
- Invalid page, size, direction, and field parameters fall back safely.

### Component coverage

- Plain tables remain renderable without Flop metadata.
- Sortable headers produce patch links that preserve unrelated query params.
- Active ascending and descending states render the expected accessible state
  and Heroicon.
- Pagination renders correct page, previous, next, current, ellipsis, and
  disabled states.
- Pagination links preserve search and sorting parameters.

### LiveView coverage

- Initial query parameters are loaded through the mounted route.
- Search patches to `q`, resets the page, and renders filtered rows.
- Sort links patch the URL and reorder visible rows.
- Page links patch the URL and render the requested records.
- Browser-style parameter changes reproduce state through `handle_params/3`.
- Invite and revoke refresh the current list without discarding search or sort.
- Unauthorized users never receive broker rows or pagination metadata in the
  rendered management surface.

Verification will run focused RED/GREEN tests, related context and LiveView
suites, formatting checks, and `mix precommit`.

## Out of Scope

- Cursor pagination and infinite scrolling.
- Multiple independently pageable regions on one LiveView.
- Replacing friendly domain filters with public nested Flop filter parameters.
- Adding JavaScript hooks for sorting or pagination.
- Migrating unrelated pages that do not yet contain pageable lists.

## References

- [Flop documentation](https://hexdocs.pm/flop/Flop.html)
- [Flop schema configuration](https://hexdocs.pm/flop/schema.html)
- [Flop Phoenix components](https://hexdocs.pm/flop_phoenix/Flop.Phoenix.html)
- [Scrivener Ecto maintenance notice](https://hexdocs.pm/scrivener_ecto/readme.html)
