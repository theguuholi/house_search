# Components and Templates

## `.ex` and `.html.heex` separation

For new route-backed LiveViews and substantial touched views, keep callbacks and helpers in `.ex` and page markup in the sibling `.html.heex` Phoenix discovers for that module. Do not define `render/1` as well.

```text
lib/house_search_web/live/property_live/
├── index.ex
└── index.html.heex
```

Tiny function components may use inline `~H`; a page or substantial component template must not. When materially touching an existing large inline template, move the touched substantial markup to the sibling template if the move remains focused. Do not retrofit unrelated legacy files.

## Function component versus LiveComponent

Use a function component for reusable markup, controls, cards, rows, empty states, and slots. Declare public `attr/3` and `slot/3` contracts.

Use `Phoenix.LiveComponent` only when a boundary needs isolated state and component-owned events. A LiveComponent requires a stable, non-nil `id`; that component identity does not automatically produce a DOM `id`.

Avoid LiveComponents used only to organize markup or render list rows. Keep the parent as the source of truth unless isolated component state has a clear lifecycle.

## Event ownership and targeting

Bind an event to the module that implements its `handle_event/3`.

```heex
<.form for={@form} id="property-form" phx-change="validate" phx-submit="save" phx-target={@myself}>
  <.input field={@form[:address]} label="Address" />
  <.button type="submit">Save</.button>
</.form>
```

Every `phx-click`, `phx-change`, `phx-submit`, key, blur, or focus event handled by a LiveComponent carries `phx-target={@myself}`. Omitting it routes the event to the parent LiveView. Parent-owned events intentionally omit the component target and must have parent handler coverage.

For child-to-parent results, send a narrow domain/UI message and handle it in the parent. Do not maintain divergent parent and component copies of persisted data.

## LiveComponent state

Use `assign_new/3` in `update/2` for component-local state that should survive parent updates. Use `assign/3` for incoming assigns and derived values that must refresh. Avoid per-component queries in `update/2`; preload through the context or use `update_many/1` when appropriate.

## CoreComponents reuse

Inspect `HouseSearchWeb.CoreComponents` and the imported Phoenix components before creating controls or patterns. Reuse `<.form>`, `<.input>`, `<.button>`, `<.link>`, `<.header>`, `<.table>`, `<.modal>`, `<.flash>`, and `<.icon>` when their contracts fit. Extend a shared component only when the behavior is genuinely reusable; do not copy its markup and styling into a page.
