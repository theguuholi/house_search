@RTK.md

# Project Notes

This project is an Elixir/Phoenix application that uses Phoenix LiveView for the
interactive web experience. Treat `lib/house_search_web/live` and HEEx templates
as first-class UI surfaces, and prefer LiveView-native patterns before adding
custom client-side behavior.

The standards baseline is Phoenix 1.7.24 and LiveView 1.0.18, as locked in
`mix.lock`. Do not introduce LiveView 1.1-only conventions without a deliberate
dependency and standards upgrade.

## Local Development

- Install and prepare dependencies: `mix setup`
- Run the project: `mix phx.server`
- Open the app at: `http://localhost:4000`
- The development endpoint is configured on port `4000` in `config/dev.exs`.

`mix setup` currently runs dependency installation, database setup, and asset
setup/build through the aliases in `mix.exs`.

## Local Rules

- `.agents/rules/liveview.md`
- `.agents/rules/liveview-tests.md`
- `.agents/rules/ecto-schema.md`

## Skill Routing

| Change | Required local skill |
|---|---|
| LiveView, LiveComponent, function component, HEEx, or hook | `phoenix-liveview-standards` |
| LiveView or component tests | `liveview-testing-standards` |
| Ecto schema, schema changeset, schema helper, or schema unit test | `ecto-schema-standards` |
| PRD task execution | `cy-execute-task` (and `cy-workflow-memory` when routed by the workflow) |
| Final verification | `cy-final-verify` |

The LiveView standards apply to new and materially touched code. Existing
generated authentication LiveViews/tests and other untouched deviations are
baseline debt: do not retrofit or flag them unless the current task materially
changes those lines.

## Local Reviewer

- `.codex/agents/house-search-liveview-reviewer.toml` — read-only, diff-scoped
  Phoenix/LiveView standards review.

## Local Skills

- `.agents/skills/phoenix-liveview-standards/SKILL.md`
- `.agents/skills/liveview-testing-standards/SKILL.md`
- `.agents/skills/ecto-schema-standards/SKILL.md`
- `.agents/skills/compozy/SKILL.md`
- `.agents/skills/cy-create-prd/SKILL.md`
- `.agents/skills/cy-create-tasks/SKILL.md`
- `.agents/skills/cy-create-techspec/SKILL.md`
- `.agents/skills/cy-execute-task/SKILL.md`
- `.agents/skills/cy-final-verify/SKILL.md`
- `.agents/skills/cy-fix-reviews/SKILL.md`
- `.agents/skills/cy-review-round/SKILL.md`
- `.agents/skills/cy-workflow-memory/SKILL.md`
- `.agents/skills/git-rebase/SKILL.md`
