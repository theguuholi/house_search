---
name: liveview-testing-standards
description: Use when adding or materially changing HouseSearch tests for LiveViews, LiveComponents, function components, HEEx interactions, PubSub, async work, navigation, or hook-to-server events.
---

# LiveView Testing Standards

Apply these standards to new and materially touched tests. Existing tests are baseline debt unless the task changes their behavior.

## Non-negotiable workflow

For every behavior change or bug fix:

1. Add the smallest focused test first.
2. Run that test and capture RED evidence: it must fail for the missing behavior or reproduced bug, not a typo, compile error, or setup failure.
3. Implement the minimum production change.
4. Rerun focused tests, then the relevant suite and project verification.

If the change is documentation/configuration-only, use the narrowest deterministic validation rather than inventing a behavioral RED test.

## HouseSearch test contract

- Use `HouseSearchWeb.ConnCase` and import `Phoenix.LiveViewTest`.
- Create data through existing `HouseSearch.*Fixtures`; do not add ExMachina.
- Exercise route-backed behavior with `live(conn, ~p"/route")` so router, session, `on_mount`, disconnected/connected mount, and template wiring are covered.
- Select forms and elements semantically with stable IDs, attributes, roles, ARIA state, and visible text when text is part of the contract.
- Use `form/3`, `element/3`, and render helpers for interactions; assert the resulting DOM or navigation behavior.
- Avoid raw rendered-HTML substring assertions when a semantic selector can express the behavior.
- In LiveView tests, assert user-visible outcomes through the page with `has_element?/2-3`; do not use `Repo.aggregate/3` or similar persistence checks to prove what the LiveView rendered.
- Test hook-to-server events with `render_hook/3`; this does not test JavaScript lifecycle code.

## Reference routing

- Test-first workflow, `ConnCase`, fixtures, organization: [workflow-and-fixtures.md](references/workflow-and-fixtures.md)
- Selectors, forms, redirects, patch/navigate behavior: [interactions-and-navigation.md](references/interactions-and-navigation.md)
- Function components, LiveComponents, targeting, hooks: [components-and-hooks.md](references/components-and-hooks.md)
- PubSub, async work, process synchronization: [pubsub-and-async.md](references/pubsub-and-async.md)

## Completion gate

- Focused RED evidence exists for behavior changes and fixes.
- The test mounts through the route unless isolation is the behavior being tested.
- Fixtures create domain data and assertions verify observable outcomes.
- Selectors express stable semantics rather than presentation markup.
- Component targeting, navigation, PubSub/async, and hook contracts are covered where changed.
- Focused tests and required project verification pass.
