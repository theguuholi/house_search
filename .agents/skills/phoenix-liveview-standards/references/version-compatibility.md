# Phoenix 1.7.24 and LiveView 1.0.18 Compatibility

The lockfile is authoritative. Verify `mix.lock` before copying current online examples.

## Supported baseline

- Route-mounted LiveViews, `live_session`, `on_mount`, `mount/3`, `handle_params/3`, events, and navigation.
- Function components, slots, global attributes, LiveComponents, `@myself`, and `update_many/1`.
- `stream/3-4`, `stream_insert/3-4`, `stream_delete/3`, and standard stream DOM contracts.
- `assign_async/3`, `start_async/3`, `handle_async/3`, and corresponding LiveViewTest helpers available in 1.0.18.
- External JavaScript hook modules registered through `new LiveSocket(..., {hooks: ...})`.
- `Phoenix.LiveView.JS` commands available in the locked release.

## Prohibited 1.1-only guidance

Do not introduce or recommend these until the dependency is deliberately upgraded and the standards are revised:

- Colocated hooks or hook definitions embedded in HEEx.
- `<.portal>` / LiveView portal conventions.
- `stream_async/4`.
- Keyed comprehensions using the HEEx `:key` attribute.
- `JS.ignore_attributes/1-2`.
- Any API copied from LiveView 1.1 documentation without confirming it exists in 1.0.18.

Use 1.0 alternatives: external registered hooks, ordinary semantic layout for overlays, `assign_async/3` plus `stream/4` when deferred list loading is needed, streams or stable DOM IDs for dynamic collections, and explicit hook/`phx-update` DOM ownership.

## Upgrade discipline

Do not quietly emulate a 1.1 API or add a compatibility shim. A dependency upgrade requires its own scoped change, release-note review, standards update, and test coverage.
