# Ecto Schema Gates

Applies to new and materially touched Ecto schemas, schema changesets, and schema unit tests. Untouched generated or legacy schemas are grandfathered.

## Documentation and type gate

- New schemas must have a module `@moduledoc` that states the table's purpose and points to nearby contexts or related schemas.
- Public domain field types should have `@typedoc` aliases when they clarify intent beyond the raw Ecto type.
- Every schema module must define `@type t :: %__MODULE__{...}` covering persisted fields, virtual fields, associations represented by ids or loaded structs when relevant, and timestamps.

## Schema structure gate

- Keep `use Ecto.Schema`, `import Ecto.Changeset`, aliases, primary key configuration, and `schema` declaration ordered consistently with nearby schemas.
- Use `@primary_key {:id, :binary_id, autogenerate: true}` and `@foreign_key_type :binary_id` for persisted application schemas unless the existing table or migration deliberately differs.
- Declare field defaults, virtual/redacted fields, enums, associations, and timestamp precision explicitly.

## Changeset gate

- Changesets must cast only caller-owned fields and stamp trusted/server-owned fields from trusted arguments or context, not from arbitrary attrs.
- Validate required fields, formats, lengths, constraints, and allowed enum/domain values close to the changeset that owns creation or state transition.
- Public changesets and domain helpers must have `@spec`; non-obvious public changesets should have `@doc` with a compact example.

## Test gate

- Every new schema gets a focused unit test file under the matching context test path.
- Schema tests cover valid changesets, required fields, normalization or derived values, constraints that can be exercised without brittle database coupling, and state-transition helpers.
- Run the focused schema test and relevant broader checks before completion.

Follow [Ecto Schema Standards](../skills/ecto-schema-standards/SKILL.md).
