# Flop Pagination Gates

- Derive `Flop.Schema` with explicit `filterable` and `sortable` allowlists,
  page-only pagination, `default_limit: 25`, `max_limit: 100`, and a deterministic
  default order ending in `id`. Keep `id` in the schema `sortable` allowlist for
  Flop, but reserve it from user-facing sort controls.
- Accept URL parameter maps in contexts. Apply friendly `q` filtering to the
  base query, remove `q` before Flop validation, and call
  `Flop.validate_and_run/3` with `for: Schema`, the project Repo, and
  `replace_invalid_params: true`.
- Treat the URL as list state. Load route-backed data only in `handle_params/3`,
  patch for search, sort, and pagination, preserve unrelated query parameters,
  and remove `page` when search changes.
- Reuse stateless shared table and pagination function components. Keep plain
  tables compatible, use real accessible links and ARIA state, and do not make
  disabled controls interactive.
- Add focused RED/GREEN context, component, and route-backed LiveView tests for
  validation fallback, query preservation, sorting, pagination, page reset,
  accessibility, and plain-table compatibility.
