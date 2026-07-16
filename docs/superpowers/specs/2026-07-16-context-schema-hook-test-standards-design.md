# Context, Schema, Hook, and Test Standards Design

## Objective

Extend HouseSearch's repository-local standards package with enforceable conventions for Phoenix contexts, Ecto schemas and queries, LiveView hook registration, ExDoc/doctest coverage, and Given/When/Then test descriptions.

The standards apply only to new and materially touched code. Untouched application code remains baseline debt.

## Standards surfaces

The package will use four focused surfaces:

1. A new `phoenix-context-standards` skill for public context APIs, operation extraction, documentation, and tests.
2. A new `ecto-schema-standards` skill for schema layout, changesets, queries, documentation, doctests, and scenario coverage.
3. The existing `phoenix-liveview-standards` skill, extended with the centralized JavaScript hook registry convention.
4. The existing `liveview-testing-standards` skill, extended with Given/When/Then naming for every new or materially touched test.

Mandatory rules will remain concise and link to detailed skill references. `AGENTS.md` will route context and schema/query work to the new skills.

## Context architecture

A context module remains the public façade for its domain:

```elixir
defmodule HouseSearch.Accounts do
  alias HouseSearch.Accounts.GetUser

  @doc """
  Returns the account-scoped user needed by account-management workflows.

  ## Examples

      iex> email = "docs-#{System.unique_integer([:positive])}@example.com"
      iex> {:ok, user} = HouseSearch.Accounts.register_user(%{email: email, password: "valid password"})
      iex> HouseSearch.Accounts.get_user(user.id).id == user.id
      true
  """
  @spec get_user(Ecto.UUID.t()) :: User.t() | nil
  def get_user(id), do: GetUser.call(id)
end
```

The 30-line rule counts only statements inside the function body. It excludes `@doc`, `@spec`, blank lines, comments, and the `def`/`end` lines.

When a context function body exceeds 30 lines, the coherent operation moves into a module beneath the context folder:

```text
lib/house_search/accounts.ex
lib/house_search/accounts/get_user.ex
test/house_search/accounts/get_user_test.exs
```

The extracted module uses the operation name (`HouseSearch.Accounts.GetUser`) and exposes the smallest appropriate `call/1`, `call/2`, or `call/3` interface. The context function remains the documented public entrypoint and delegates to it. Callers do not bypass the context façade.

Each extracted operation receives a mirrored test file. Tests cover successful results, relevant errors, scope/authorization boundaries, and persistence or broadcast effects.

## Query architecture

Reusable or non-trivial query builders live under a `queries/` folder:

```text
lib/house_search/accounts/queries/list_users.ex
test/house_search/accounts/queries/list_users_test.exs
```

Context APIs call query modules rather than exposing query construction to LiveViews or controllers. Query tests cover every supported scenario, including:

- scope or tenant isolation;
- each filter and supported filter combination;
- ordering and deterministic tie-breaking;
- empty, single-result, and multiple-result behavior;
- required joins and preloads;
- exclusion of unauthorized or inactive data where applicable.

## Documentation and doctests

Every public module receives an ExDoc `@moduledoc` explaining what domain concept or operation it represents and why it exists. Every public function receives:

- an ExDoc `@doc` explaining why the function exists and its observable contract;
- an `@spec`;
- at least one executable `iex>` example exercised by `doctest`.

Database-backed doctests are mandatory in addition to normal ExUnit tests. Their test module uses `HouseSearch.DataCase`, enabling SQL sandbox ownership. Examples use public context APIs and collision-safe unique data; they do not depend on execution order or hidden pre-existing rows.

Private functions cannot be published by ExDoc. Extracted or non-obvious private helpers therefore receive a concise purpose comment explaining why the helper exists. Obvious pipeline helpers do not need narration that merely restates their name.

## Schema standard

New and materially touched schemas follow this order:

1. `@moduledoc` describing the domain entity and its consumers.
2. `use Ecto.Schema` and imports.
3. aliases.
4. complete `@type t :: %__MODULE__{...}` including identifiers, fields, associations when loaded, and timestamps.
5. binary UUID primary/foreign-key declarations.
6. `schema` fields, associations, and `timestamps(type: :utc_datetime)`.
7. documented and specified public changeset/query helpers.
8. private helpers.

Changesets document why they exist and how scope controls ownership. They cast only permitted user fields, derive protected ownership fields from scope, validate every required domain invariant, and declare database constraints matching migrations.

Each schema receives a mirrored test file with normal ExUnit scenarios and doctest registration. Changeset tests cover:

- valid attributes;
- every required field and validation boundary;
- defaults;
- protected fields that must not be client-controlled;
- scope-derived ownership;
- association behavior;
- unique, foreign-key, and check constraints, including the repository operation needed to surface database constraints;
- update-specific behavior when the schema supports updates.

## Hook registry

LiveView 1.0-compatible hooks live in individual files under `assets/js/hooks/`. The folder owns one registry:

```text
assets/js/hooks/
├── index.js
├── propertyMap.js
└── anotherHook.js
```

`assets/js/hooks/index.js` imports every hook and exports one `Hooks` object. `assets/js/app.js` imports that registry and passes it to `LiveSocket`:

```javascript
import Hooks from "./hooks/index"

const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks,
})
```

No hook may be registered ad hoc in `app.js`. Existing hook requirements remain: stable DOM ID, minimal DOM ownership, cleanup in `destroyed()`, explicit payload contract, and `render_hook/3` server-contract coverage. Colocated LiveView 1.1 hooks remain prohibited.

The implementation will add an empty registry and wire it into `app.js`, establishing the required structure before the first concrete hook.

## Test language and structure

Every new or materially touched ExUnit test description uses a Given/When/Then sentence:

```elixir
test "given a user on the accounts page, when they click New user, then the modal opens" do
  # Arrange / Given
  # Act / When
  # Assert / Then
end
```

The test body remains Arrange/Act/Assert and verifies observable behavior. The description must state concrete preconditions, one action, and one outcome. It must not use generic wording such as “works,” “handles data,” or “test user.”

This naming standard applies to context, schema, query, LiveView, component, hook-contract, controller, and other new or materially touched tests. Existing untouched test names are grandfathered.

## Reviewer and enforcement

Add concise mandatory rules:

- `.agents/rules/contexts.md`
- `.agents/rules/ecto-schemas.md`

Update existing LiveView and LiveView-test rules for the hook registry and Given/When/Then descriptions. Extend the read-only reviewer to check only changed lines for:

- context façade bypass or a function body above 30 lines without extraction;
- missing operation/query module tests;
- missing module/function documentation, specs, doctest examples, or doctest registration;
- incomplete schema types/layout and incomplete changeset/query scenario coverage;
- hooks outside the registry or missing `hooks: Hooks` wiring;
- non-Given/When/Then test descriptions.

Each finding maps to an exact rule or skill heading and includes a compatible correction. Untouched legacy deviations remain out of scope.

## Validation and acceptance

The change is accepted when:

- both new skills have generated `agents/openai.yaml` metadata and pass `quick_validate.py`;
- modified existing skills still pass `quick_validate.py`;
- every path referenced by `AGENTS.md` and the rules exists;
- the reviewer TOML parses;
- forward tests demonstrate correct context extraction, schema/changeset/query coverage, database-backed doctests, hook registry wiring, and Given/When/Then naming;
- reviewer calibration catches representative violations and ignores grandfathered code;
- `mix format --check-formatted` passes;
- `mix precommit` passes, with unrelated pre-existing failures reported separately.

No existing context, schema, query, or test file will be retrofitted as part of this standards package, except the behavior-neutral empty hook registry wiring in `assets/js/app.js`.
