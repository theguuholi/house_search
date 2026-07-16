# Workflow, ConnCase, and Fixtures

## Focused RED evidence

Write one test that states the missing outcome. Run the smallest command that includes it, commonly:

```sh
mix test test/house_search_web/live/property_live_test.exs:42
```

Record the command and relevant expected assertion failure in the task/PR handoff. A compile error, missing fixture, bad route, or selector typo is not RED evidence. Fix the test harness until the assertion fails because production behavior is absent or wrong.

For a bug, reproduce the reported failure first. Do not weaken an existing assertion to make implementation easier.

## Test module baseline

```elixir
defmodule HouseSearchWeb.PropertyLiveTest do
  use HouseSearchWeb.ConnCase, async: true

  import HouseSearch.AccountsFixtures
  import HouseSearch.PropertiesFixtures
  import Phoenix.LiveViewTest
end
```

Use `async: false` when the test shares a named/global process, requires shared sandbox access from spawned processes, or has another demonstrated isolation constraint. Do not disable async by habit.

## Fixtures only

Use existing `HouseSearch.*Fixtures` to create valid data through public contexts. Add a focused fixture helper when a new domain entity needs repeatable setup. Do not add ExMachina, factory macros, or bare structs as a substitute for persisted domain setup.

Direct `Repo` setup in a LiveView test is a last resort for a state impossible to reach through the public domain API. Prefer a fixture/context helper and keep persistence assertions at the context boundary when the visible behavior already proves the outcome.

## Organization and scope

- Test names state the observable outcome.
- Keep arrange, act, and assert visually distinct.
- One test should prove one behavior; split unrelated success, validation, authorization, and navigation outcomes.
- Parent LiveView tests cover route/lifecycle/parent events. Give a stateful component a focused test file when its behavior is substantial, while still mounting through a host route for interaction coverage.
- Assert public UI/domain effects, not assigns or callback implementation details.

## Verification progression

1. Focused line/test file during RED/GREEN.
2. All directly related LiveView and context tests.
3. `mix format --check-formatted`.
4. `mix precommit` before completion.

Report unrelated pre-existing failures separately; do not silently fold them into the change.
