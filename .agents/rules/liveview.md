# LiveView Production Gates

Applies to new and materially touched LiveViews, LiveComponents, function components, HEEx, and hooks. Untouched legacy code is grandfathered.

## Version gate

- Target Phoenix 1.7.24 and LiveView 1.0.18.
- Reject LiveView 1.1-only guidance or APIs. Follow [Phoenix LiveView Standards — Version contract](../skills/phoenix-liveview-standards/SKILL.md#version-contract).

## Boundary and lifecycle gate

- LiveViews/components must use contexts for data access; direct `Repo` access and socket-to-context coupling are forbidden.
- Connected-only subscriptions/work must be guarded by `connected?/1`; PubSub contracts must be scoped.
- Handle context success and failure explicitly.
- Follow [Lifecycle and Context Boundaries](../skills/phoenix-liveview-standards/references/lifecycle-and-contexts.md).

## Template and component gate

- New route-backed and substantially touched page markup must use sibling `.ex`/`.html.heex` files; no new substantial inline `~H` template.
- Reuse CoreComponents; default to function components. LiveComponents require isolated state plus component-owned events.
- Every LiveComponent-owned event binding must include `phx-target={@myself}`.
- Follow [Components and Templates](../skills/phoenix-liveview-standards/references/components-and-templates.md).

## HEEx and accessibility gate

- Use semantic elements, real controls, accessible names/states, stable IDs, and labeled forms.
- Follow [HEEx and Accessibility](../skills/phoenix-liveview-standards/references/heex-and-accessibility.md).

## Hook gate

- Hooks require a stable ID, explicit `LiveSocket` registration, minimal/documented DOM ownership, and cleanup of every created resource.
- Hook-to-server events require `render_hook/3` server-contract coverage. JavaScript lifecycle automation is out of scope.
- Follow [LiveView 1.0 Hooks](../skills/phoenix-liveview-standards/references/hooks.md).
