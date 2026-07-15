@RTK.md

# Project Notes

This project is an Elixir/Phoenix application that uses Phoenix LiveView for the
interactive web experience. Treat `lib/house_search_web/live` and HEEx templates
as first-class UI surfaces, and prefer LiveView-native patterns before adding
custom client-side behavior.

Note: `RTK.md` is referenced above as the shared instruction entrypoint, but the
file is not present in this checkout at the time this note was written.

## Local Development

- Install and prepare dependencies: `mix setup`
- Run the project: `mix phx.server`
- Open the app at: `http://localhost:4000`
- The development endpoint is configured on port `4000` in `config/dev.exs`.

`mix setup` currently runs dependency installation, database setup, and asset
setup/build through the aliases in `mix.exs`.

## Local Rules

Rules should live in `.agents/rules`. That directory is not present in this
checkout yet. When rules are added, keep one pointer here per rule file.

## Local Skills

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
