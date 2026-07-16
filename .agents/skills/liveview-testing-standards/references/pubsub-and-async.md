# PubSub and Async Behavior

## Synchronize with messages, not time

Never use `Process.sleep/1` to make an async or PubSub test pass. Prefer deterministic messages, `assert_receive`, monitors, `render_async/2`, or direct delivery to the mounted LiveView process when the unit under test is `handle_info/2`.

## PubSub coverage

Separate two contracts when both matter:

1. The context publishes the documented message on the scoped topic.
2. The mounted LiveView reacts to that message and updates semantic DOM state.

Subscribe the test process before invoking a context mutation, then use `assert_receive` for the broadcast contract. For the LiveView reaction, mount the route, deliver the documented message to `view.pid` when testing `handle_info/2` deterministically, and assert the updated DOM.

```elixir
send(view.pid, {:property_updated, property})

assert has_element?(view, "#property-#{property.id}[data-status='archived']")
```

Use a real broadcast integration test only when subscription wiring or topic scope is the behavior. Synchronize on an observable message/state; do not invent polling sleeps.

For a real broadcast path, have the context mutation broadcast a domain message that includes an acknowledgement/reference the test can `assert_receive`, or monitor/send a completion message from the LiveView handler in a test-only injected boundary. Assert that signal before querying the rendered DOM; do not render immediately after an unacknowledged broadcast.

## Async assigns and tasks

For `assign_async/3` or `start_async/3`, assert the initial loading contract when relevant, then let LiveViewTest drain current async work with `render_async/2` and assert success/error UI.

```elixir
assert has_element?(view, "#property-summary[data-status='loading']")

render_async(view, 1_000)

assert has_element?(view, "#property-summary[data-status='ready']")
```

Use an explicit timeout only when the operation justifies it. Async work that accesses the database must have SQL sandbox ownership; prefer `async: false` with shared sandbox only when spawned-process database access requires it.

Test error behavior as an observable state, not merely that `handle_async/3` exists.

## Flake diagnosis

A timing-dependent failure is a synchronization defect. Identify the producer/consumer boundary and wait for its actual signal. Increasing sleeps or retry counts hides the contract and is not an acceptable fix.
