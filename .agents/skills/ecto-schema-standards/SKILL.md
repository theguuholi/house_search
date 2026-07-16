---
name: ecto-schema-standards
description: Use when creating or materially changing HouseSearch Ecto schemas, schema changesets, schema helper functions, schema typespecs, or schema unit tests.
---

# Ecto Schema Standards

Apply these standards to new and materially touched Ecto schemas. Untouched legacy or generated schemas are baseline debt; do not retrofit unrelated files unless the current task changes them.

## Mandatory boundaries

1. Schemas describe data shape, narrow changeset validation, and small schema-local helpers. Context modules own domain workflows and persistence orchestration.
2. Never trust caller-provided attrs for server-owned fields such as `account_id`, audit fields, state-transition timestamps, or ids derived from authenticated scope. Pass trusted values explicitly and stamp them in the changeset.
3. Every new schema must have a focused unit test file with `doctest SchemaModule`. A schema without schema-level tests and doctests is incomplete.
4. Keep schema docs, examples, and types close to the schema so ExDoc output explains field intent without reverse-engineering migrations.

## Required schema shape

Use this order unless nearby code has a stronger established pattern:

1. `use Ecto.Schema`
2. `import Ecto.Changeset`
3. aliases
4. `@moduledoc`
5. module attributes for enum values and other shared schema constants
6. public `@typedoc` / `@type` aliases
7. `@type t :: %__MODULE__{...}`
8. `@primary_key` / `@foreign_key_type`
9. `schema`
10. public changesets and helpers with `@doc` / `@spec`
11. private helpers

Persisted app schemas should default to:

```elixir
@primary_key {:id, :binary_id, autogenerate: true}
@foreign_key_type :binary_id
```

Use the timestamp precision already required by the table and neighboring context.

## Documentation, doctests, and types

- `@moduledoc` states what one row represents and links related context/schema modules.
- Public changesets and helpers that have deterministic, isolated behavior should include a compact `## Examples` block in `@doc` using `iex>` examples that can run as doctests.
- Doctest examples should prefer pure schema helpers, normalizers, predicates, and changeset validity/error assertions. Do not doctest Repo calls, clock-dependent behavior, random token generation, or brittle database constraints.
- Keep examples ExDoc-friendly: use fully-qualified module names when that makes output clearer, avoid hidden test setup, and make assertions readable in generated docs.
- Add `@typedoc` aliases for domain-significant strings, enums, booleans, and identifiers when they make allowed meaning clearer.
- Define every `Ecto.Enum` value list as a plural module attribute above the related type, such as `@system_roles ~w/admin member/a`, then use `values: @system_roles` in the field.
- Typespecs cannot use a runtime values attribute directly. Mirror enum attributes with an explicit union type, such as `@type system_role :: :admin | :member`, and keep the attribute and type next to each other.
- Define `@type t :: %__MODULE__{...}` with nullable persisted fields as `type | nil`, defaults as their runtime type, and timestamps as `DateTime.t() | nil`.
- Use `%__MODULE__{}` in types and pattern matches. Do not write `%**MODULE**{}`.

## Changesets

- Cast only fields controlled by the caller for that operation.
- Define cast lists as module attributes: `@fields` for optional caller-owned fields and `@required_fields` for required caller-owned fields. If every cast field is required, set `@fields []` and put all fields in `@required_fields`.
- Use `cast(attrs, @fields ++ @required_fields)` and `validate_required(@required_fields)` instead of repeating literal field lists.
- Stamp trusted fields from `Scope.t()`, current user/account, `now`, or explicit function args.
- Validate required data and domain constraints in the changeset that accepts or transitions that data.
- Use `unique_constraint/3`, `foreign_key_constraint/3`, and check constraints when backed by migrations.
- Add `@spec` to every public changeset/helper. Add a compact `@doc` when the function is public or non-obvious.

## Schema unit tests and doctests

Create or update a matching test file such as:

```text
test/house_search/accounts/invitation_test.exs
```

Start the file with a doctest for the schema module:

```elixir
defmodule HouseSearch.Accounts.InvitationTest do
  use HouseSearch.DataCase, async: true

  doctest HouseSearch.Accounts.Invitation
end
```

Cover:

- doctests for deterministic public docs examples
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

  @statuses ~w/pending accepted revoked/a
  @fields [:status]
  @required_fields [:email, :name, :inviter_id, :expires_at]

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
    field :status, Ecto.Enum, values: @statuses, default: :pending
    field :expires_at, :utc_datetime_usec
    field :accepted_at, :utc_datetime_usec
    belongs_to :accepted_user, User
    belongs_to :accepted_account, Account

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Builds an invitation changeset and normalizes the recipient email.

  ## Examples

      iex> changeset = HouseSearch.Accounts.Invitation.changeset(%HouseSearch.Accounts.Invitation{}, %{email: " USER@Example.COM ", name: "User", inviter_id: Ecto.UUID.generate(), expires_at: DateTime.utc_now()})
      iex> Ecto.Changeset.get_change(changeset, :email)
      "user@example.com"
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(invitation, attrs) do
    invitation
    |> cast(attrs, @fields ++ @required_fields)
    |> update_change(:email, &normalize_email/1)
    |> validate_required(@required_fields)
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

  @doc """
  Returns true when an invitation is pending and has not expired.

  ## Examples

      iex> future = DateTime.add(DateTime.utc_now(), 60, :second)
      iex> HouseSearch.Accounts.Invitation.usable?(%HouseSearch.Accounts.Invitation{status: :pending, expires_at: future}, DateTime.utc_now())
      true
  """
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
- New schema has a focused unit test file with `doctest SchemaModule`.
- Public deterministic docs examples render through ExDoc and pass through doctest.
- Focused tests pass, `mix docs` succeeds for doc/example changes, and broader verification is run according to task risk.
