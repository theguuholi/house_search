---
name: phoenix-liveview-standards
description: Use when creating or materially changing HouseSearch Phoenix LiveViews, LiveComponents, function components, HEEx templates, PubSub handling, or JavaScript hooks.
---

# Phoenix LiveView Standards

Apply these standards to new and materially touched code. Untouched LiveViews, including generated auth code, are baseline debt rather than retrofit targets.

## Version contract

Target Phoenix 1.7.24 and LiveView 1.0.18. Do not introduce or recommend LiveView 1.1-only APIs or conventions. Read [version-compatibility.md](references/version-compatibility.md) whenever an API's availability is uncertain.

## Mandatory boundaries

1. LiveViews and LiveComponents coordinate UI state; contexts own domain operations and persistence.
2. Never call or alias `HouseSearch.Repo` in a LiveView or LiveComponent. Add a context function instead. Never pass a socket into a context.
3. New route-backed LiveViews and substantial touched views split callbacks into `.ex` and markup into sibling `.html.heex`; do not add substantial inline `~H` templates.
4. Reuse `HouseSearchWeb.CoreComponents` before adding custom controls. Prefer function components; use a LiveComponent only for isolated state plus component-owned events.
5. The module that handles an event owns its binding. A LiveComponent-owned binding includes `phx-target={@myself}`.
6. Use semantic, accessible HTML and stable DOM contracts. Hooks are a last-mile bridge, not a second UI framework.
7. Subscribe only during connected mount and keep PubSub topics scoped to the domain boundary.

## Workflow

1. Confirm the locked framework versions in `mix.lock`.
2. Identify the context API, event owner, render boundary, and server-visible behavior before editing.
3. Open only the references matching the change.
4. Implement with focused RED evidence under `liveview-testing-standards` for behavior changes and bug fixes.
5. Review new/touched lines against `.agents/rules/liveview.md`.

## Reference routing

- Lifecycle, route mounting, contexts, callbacks, PubSub: [lifecycle-and-contexts.md](references/lifecycle-and-contexts.md)
- File split, function components, LiveComponents, event targeting: [components-and-templates.md](references/components-and-templates.md)
- Semantic HTML, accessibility, forms, CoreComponents: [heex-and-accessibility.md](references/heex-and-accessibility.md)
- LiveView 1.0 hooks, registration, cleanup, server contracts: [hooks.md](references/hooks.md)
- Supported and prohibited version features: [version-compatibility.md](references/version-compatibility.md)

## Completion gate

- No direct `Repo` access or socket-to-context coupling.
- New substantial markup lives in `.html.heex`.
- Component event bindings target their owner.
- CoreComponents and semantic elements are used where applicable.
- PubSub and hooks satisfy their lifecycle contracts.
- Guidance and code remain LiveView 1.0.18-compatible.
