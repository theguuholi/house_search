---
name: ecto-schema-standards
description: Use when creating or materially changing HouseSearch Ecto schemas, schema changesets, schema helper functions, schema typespecs, or schema unit tests.
---

# Ecto Schema Standards

Apply these standards to new and materially touched Ecto schemas. Untouched legacy or generated schemas are baseline debt; do not retrofit unrelated files unless the current task changes them.

## Mandatory boundaries

1. Schemas describe data shape, narrow changeset validation, and small schema-local helpers. Context modules own domain workflows and persistence orchestration.
2. Never trust caller-provided attrs for server-owned fields such as `account_id`, audit fields, state-transition timestamps, or ids derived from authenticated scope. Pass trusted values explicitly and stamp them in the changeset.
3. Every new schema must have a focused unit test file. A schema without schema-level tests is incomplete.
4. Keep schema docs and types close to the schema so future agents can understand field intent without reverse-engineering migrations.

## Required schema shape

Use this order unless nearby code has a stronger established pattern:

1. `use Ecto.Schema`
2. `import Ecto.Changeset`
3. aliases
4. `@moduledoc`
5. public `@typedoc` / `@type` aliases
6. `@type t :: %__MODULE__{...}`
7. `@primary_key` / `@foreign_key_type`
8. `schema`
9. public changesets and helpers with `@doc` / `@spec`
10. private helpers

Persisted app schemas should default to:

```elixir
@primary_key {:id, :binary_id, autogenerate: true}
@foreign_key_type :binary_id
```

Use the timestamp precision already required by the table and neighboring context.

## Documentation and types

- `@moduledoc` states what one row represents and links related context/schema modules.
- Add `@typedoc` aliases for domain-significant strings, enums, booleans, and identifiers when they make allowed meaning clearer.
- Define `@type t :: %__MODULE__{...}` with nullable persisted fields as `type | nil`, defaults as their runtime type, and timestamps as `DateTime.t() | nil`.
- Use `%__MODULE__{}` in types and pattern matches. Do not write `%**MODULE**{}`.

## Changesets

- Cast only fields controlled by the caller for that operation.
- Stamp trusted fields from `Scope.t()`, current user/account, `now`, or explicit function args.
- Validate required data and domain constraints in the changeset that accepts or transitions that data.
- Use `unique_constraint/3`, `foreign_key_constraint/3`, and check constraints when backed by migrations.
- Add `@spec` to every public changeset/helper. Add a compact `@doc` when the function is public or non-obvious.

## Schema unit tests

Create or update a matching test file such as:

```text
test/house_search/accounts/invitation_test.exs
```

Cover:

- valid changeset accepts the intended attrs
- required fields are enforced
- normalization or derived fields happen
- state-transition helpers change only the expected fields
- public predicates cover true and false cases
- constraints when the required database setup is stable and focused

Prefer asserting changeset fields and errors directly. Use fixtures only when the schema requires associated persisted records.

## Example pattern

```elixir
defmodule HouseSearch.Accounts.Invitation do
  @moduledoc """
  Represents an invitation for a person to join an account.

  Invitations store recipient details, lifecycle status, token hash data, and
  acceptance metadata. See `HouseSearch.Accounts`, `HouseSearch.Accounts.User`,
  and `HouseSearch.Accounts.Account`.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias HouseSearch.Accounts.Account
  alias HouseSearch.Accounts.User

  @typedoc "Normalized recipient email address."
  @type email :: String.t()

  @typedoc "Invitation lifecycle state."
  @type status :: :pending | :accepted | :revoked

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          token: String.t() | nil,
          token_hash: binary() | nil,
          email: email() | nil,
          name: String.t() | nil,
          inviter_id: Ecto.UUID.t() | nil,
          inviter: User.t() | Ecto.Association.NotLoaded.t() | nil,
          status: status(),
          expires_at: DateTime.t() | nil,
          accepted_at: DateTime.t() | nil,
          accepted_user_id: Ecto.UUID.t() | nil,
          accepted_user: User.t() | Ecto.Association.NotLoaded.t() | nil,
          accepted_account_id: Ecto.UUID.t() | nil,
          accepted_account: Account.t() | Ecto.Association.NotLoaded.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "invitations" do
    field :token, :string, virtual: true, redact: true
    field :token_hash, :binary, redact: true
    field :email, :string
    field :name, :string
    belongs_to :inviter, User
    field :status, Ecto.Enum, values: [:pending, :accepted, :revoked], default: :pending
    field :expires_at, :utc_datetime_usec
    field :accepted_at, :utc_datetime_usec
    belongs_to :accepted_user, User
    belongs_to :accepted_account, Account

    timestamps(type: :utc_datetime_usec)
  end

  @doc "Builds an invitation changeset and normalizes the recipient email."
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(invitation, attrs) do
    invitation
    |> cast(attrs, [:email, :name, :inviter_id, :expires_at, :status])
    |> update_change(:email, &normalize_email/1)
    |> validate_required([:email, :name, :inviter_id, :expires_at])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> validate_length(:name, min: 1, max: 160)
    |> unique_constraint(:email, name: :invitations_pending_email_index)
  end

  @spec token_changeset(t(), String.t()) :: Ecto.Changeset.t()
  def token_changeset(invitation, token) do
    invitation
    |> change(token: token, token_hash: hash_token(token))
    |> validate_required([:token_hash])
    |> unique_constraint(:token_hash)
  end

  @spec accept_changeset(t(), Ecto.UUID.t(), Ecto.UUID.t(), DateTime.t()) :: Ecto.Changeset.t()
  def accept_changeset(invitation, user_id, account_id, now) do
    change(invitation,
      status: :accepted,
      accepted_at: now,
      accepted_user_id: user_id,
      accepted_account_id: account_id
    )
  end

  @spec revoke_changeset(t()) :: Ecto.Changeset.t()
  def revoke_changeset(invitation), do: change(invitation, status: :revoked)

  @spec usable?(t(), DateTime.t()) :: boolean()
  def usable?(%__MODULE__{status: :pending, expires_at: expires_at}, now) do
    DateTime.before?(now, expires_at)
  end

  def usable?(_, _), do: false

  @spec unusable_reason(t()) :: :already_accepted | :revoked | :expired
  def unusable_reason(%__MODULE__{status: :accepted}), do: :already_accepted
  def unusable_reason(%__MODULE__{status: :revoked}), do: :revoked
  def unusable_reason(%__MODULE__{}), do: :expired

  @spec hash_token(String.t()) :: binary()
  def hash_token(token) when is_binary(token), do: :crypto.hash(:sha256, token)

  @spec normalize_email(String.t() | term()) :: String.t() | term()
  def normalize_email(email) when is_binary(email), do: email |> String.trim() |> String.downcase()
  def normalize_email(email), do: email
end
```

## Completion gate

- New/touched schema satisfies `.agents/rules/ecto-schema.md`.
- New schema has a focused unit test file.
- Focused tests pass, and broader verification is run according to task risk.
