# LiveView Test Gates

Applies to new and materially touched LiveView/component tests. Untouched legacy tests are grandfathered.

## RED gate

- Behavior changes and bug fixes require focused RED evidence before production changes: command, expected assertion failure, and the reason it proves missing/broken behavior.
- A compile/setup/selector error is not valid RED evidence.
- Follow [Workflow, ConnCase, and Fixtures](../skills/liveview-testing-standards/references/workflow-and-fixtures.md).

## Harness and fixture gate

- Use `HouseSearchWeb.ConnCase`, `Phoenix.LiveViewTest`, and existing `HouseSearch.*Fixtures`.
- Mount through the real route by default. Do not add ExMachina.

## Assertion and interaction gate

- Assert observable behavior with `has_element?/2-3` and stable semantic selectors. Stable IDs/ARIA selectors do not need visible text unless copy is the contract.
- Drive forms and events through `form/3` and `element/3`; do not use brittle raw-HTML substring assertions when selectors apply.
- Verify redirect, navigate, and patch destinations and resulting behavior.
- Follow [Interactions and Navigation](../skills/liveview-testing-standards/references/interactions-and-navigation.md).

## Component and hook gate

- Test substantial LiveComponents through a real parent/host and interact through targeted elements so `phx-target` is exercised.
- Use focused `render_component/2` only for pure component rendering contracts.
- Test every changed hook-to-server event with `render_hook/3`; do not claim it covers JavaScript lifecycle behavior.
- Follow [Components and Hook Contracts](../skills/liveview-testing-standards/references/components-and-hooks.md).

## Async and verification gate

- Synchronize PubSub/async tests with messages, monitors, or `render_async/2`; never `Process.sleep/1`.
- Run focused tests, related suites, `mix format --check-formatted`, and `mix precommit`. Separate pre-existing failures from change-attributable failures.
- Follow [PubSub and Async Behavior](../skills/liveview-testing-standards/references/pubsub-and-async.md).
