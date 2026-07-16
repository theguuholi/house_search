# Ecto Schema Gates

Applies to new and materially touched Ecto schemas, schema changesets, and schema unit tests. Untouched generated or legacy schemas are grandfathered.

## Documentation and type gate

- New schemas must have a module `@moduledoc` that states the table's purpose and points to nearby contexts or related schemas.
- Public deterministic schema helpers and changesets should include ExDoc-friendly `## Examples` blocks that can run as doctests.
- Public domain field types should have `@typedoc` aliases when they clarify intent beyond the raw Ecto type.
- Every schema module must define `@type t :: %__MODULE__{...}` covering persisted fields, virtual fields, associations represented by ids or loaded structs when relevant, and timestamps.

## Schema structure gate

- Keep `use Ecto.Schema`, `import Ecto.Changeset`, aliases, primary key configuration, and `schema` declaration ordered consistently with nearby schemas.
- Use `@primary_key {:id, :binary_id, autogenerate: true}` and `@foreign_key_type :binary_id` for persisted application schemas unless the existing table or migration deliberately differs.
- Declare field defaults, virtual/redacted fields, enums, associations, and timestamp precision explicitly.
- Every `Ecto.Enum` field must use a plural module attribute for values, such as `@system_roles ~w/admin member/a` with `values: @system_roles`; keep the matching enum `@type` union next to the attribute.

## Changeset gate

- Changesets must cast only caller-owned fields and stamp trusted/server-owned fields from trusted arguments or context, not from arbitrary attrs.
- Changesets must use module attributes for cast lists: `@fields` for optional caller-owned fields and `@required_fields` for required caller-owned fields. If every cast field is required, `@fields` must be empty. Use `cast(attrs, @fields ++ @required_fields)` and `validate_required(@required_fields)`.
- Validate required fields, formats, lengths, constraints, and allowed enum/domain values close to the changeset that owns creation or state transition.
- Public changesets and domain helpers must have `@spec`; non-obvious public changesets should have `@doc` with a compact doctest-ready example when the behavior is deterministic and isolated.

## Test gate

- Every new schema gets a focused unit test file under the matching context test path.
- New schema test files must include `doctest SchemaModule` so ExDoc examples are executable.
- Schema tests cover valid changesets, required fields, normalization or derived values, constraints that can be exercised without brittle database coupling, and state-transition helpers.
- Run the focused schema test, `mix docs` for documentation/example changes, and relevant broader checks before completion.

Follow [Ecto Schema Standards](../skills/ecto-schema-standards/SKILL.md).
