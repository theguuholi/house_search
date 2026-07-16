# Interactions and Navigation

## Route mounting

Prefer the real route:

```elixir
{:ok, view, _html} =
  conn
  |> log_in_user(user_fixture())
  |> live(~p"/properties")
```

This covers router/session/auth hooks, both mount phases, and the discovered `.html.heex` template. Use `live_isolated/3` only when intentionally testing an isolated LiveView contract that has no meaningful route.

## Selector policy

Preferred selector signals:

1. Stable element/form IDs and domain-record IDs.
2. Semantic element plus name/type/href or meaningful ARIA attributes/state.
3. Visible text when copy or accessible name is part of the behavior.
4. Narrow `data-*` state only when it is a deliberate UI contract.

Stable IDs or ARIA selectors are sufficient without visible text when the test concerns presence, wiring, or state rather than copy. Do not require text mechanically.

Avoid utility CSS classes, DOM depth, full HTML snapshots, `html =~`, and `render(view) =~` when `has_element?/2-3` can state the same contract.

```elixir
assert has_element?(view, "#property-form input[name='property[address]']")
assert has_element?(view, "button[aria-expanded='true']")
refute has_element?(view, "#property-#{property.id}")
```

## Forms and events

Drive events through the bound element so the test verifies event name, payload shape, target, and DOM wiring.

```elixir
view
|> form("#property-form", property: %{address: "Rua A"})
|> render_change()

view
|> form("#property-form", property: %{address: "Rua A"})
|> render_submit()

assert has_element?(view, "#properties", "Rua A")
```

Use `element/3 |> render_click()` for click events. Calling `render_click(view, "event", payload)` is appropriate only when directly testing a LiveView event contract; it does not prove template targeting.

## Redirects and live navigation

Assert the navigation primitive produced by the implementation:

- External/controller redirect: pipe the interaction result to `follow_redirect/3` and assert the destination response.
- Live redirect/navigation: use `assert_redirect/2` or the matching `follow_redirect/3` flow supported by LiveViewTest.
- Patch: use `assert_patch/2`, then assert URL-driven DOM state.

```elixir
{:ok, destination_conn} =
  view
  |> form("#property-form", property: valid_attrs)
  |> render_submit()
  |> follow_redirect(conn, ~p"/properties")

assert html_response(destination_conn, 200)
```

Do not assert only that a redirect tuple exists; verify the intended destination and, when relevant, its resulting UI.
