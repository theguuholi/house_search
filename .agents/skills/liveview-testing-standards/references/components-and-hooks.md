# Components and Hook Contracts

## Function components

Use `render_component/2` for a pure function component's focused rendering contract when routing through a page would add irrelevant setup. Assert semantic elements with Floki or a minimal host LiveView when `has_element?` interactions are important. Do not duplicate page-level coverage for every markup fragment.

## Stateful LiveComponents

Exercise substantial stateful components through a real parent route or a purpose-built test host LiveView. Interact through the component's bound element so LiveViewTest follows `phx-target`:

```elixir
view
|> element("#favorite-#{property.id}", "Favorite")
|> render_click()

assert has_element?(view, "#favorite-#{property.id}[aria-pressed='true']")
```

This proves the template target and handler ownership together. A direct `render_click(view, "favorite", ...)` sends to the parent and cannot prove a LiveComponent contract.

Cover `update/2` state preservation when parent re-renders are material to the component. Assert observable DOM state rather than reading the component socket.

## Hook-to-server events

First assert the hook root contract, including its stable ID:

```elixir
assert has_element?(view, "#property-map[phx-hook='PropertyMap']")
```

Then call `render_hook/3` with the exact event and payload shape the JavaScript hook pushes:

```elixir
view
|> render_hook("bounds_changed", %{
  "north" => -23.4,
  "south" => -23.8,
  "east" => -46.3,
  "west" => -46.9
})

assert has_element?(view, "#property-map[data-filtered='true']")
```

For a LiveComponent-owned hook event, call `render_hook/3` on an `element/3` that contains the component target:

```elixir
view
|> element("#property-map[phx-target]")
|> render_hook("bounds_changed", payload)
```

`render_hook/3` validates the server event contract only. It does not run the hook module, browser APIs, `mounted()`, `updated()`, or `destroyed()`. Direct JavaScript lifecycle automation and a JavaScript runner are outside this package.
