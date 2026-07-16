defmodule HouseSearch.Accounts.Invitation do
  @moduledoc """
  Represents an invitation for a broker to join the invite-only pilot.

  Invitations store recipient details, token hash data, lifecycle state, and
  acceptance metadata. See `HouseSearch.Accounts`, `HouseSearch.Accounts.User`,
  and `HouseSearch.Accounts.Account`.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias HouseSearch.Accounts.Account
  alias HouseSearch.Accounts.User

  @statuses ~w/pending accepted revoked/a
  @fields []
  @required_fields [:email, :name]
  @trusted_required_fields [:inviter_id, :expires_at]
  @token_required_fields [:token_hash]

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
  Builds an invitation changeset and stamps trusted inviter and expiry data.

  ## Examples

      iex> inviter_id = Ecto.UUID.generate()
      iex> expires_at = ~U[2026-07-23 12:00:00Z]
      iex> changeset = HouseSearch.Accounts.Invitation.changeset(%HouseSearch.Accounts.Invitation{}, %{email: " USER@Example.COM ", name: "User"}, inviter_id, expires_at)
      iex> Ecto.Changeset.get_change(changeset, :email)
      "user@example.com"
  """
  @spec changeset(t(), map(), Ecto.UUID.t(), DateTime.t()) :: Ecto.Changeset.t()
  def changeset(invitation, attrs, inviter_id, %DateTime{} = expires_at) do
    invitation
    |> cast(attrs, @fields ++ @required_fields)
    |> put_change(:inviter_id, inviter_id)
    |> put_change(:expires_at, expires_at)
    |> update_change(:email, &normalize_email/1)
    |> validate_required(@required_fields ++ @trusted_required_fields)
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> validate_length(:name, min: 1, max: 160)
    |> unique_constraint(:email, name: :invitations_pending_email_index)
  end

  @doc """
  Stores a one-time invitation token and its hash.
  """
  @spec token_changeset(t() | Ecto.Changeset.t(), String.t()) :: Ecto.Changeset.t()
  def token_changeset(invitation, token) do
    invitation
    |> change(token: token, token_hash: hash_token(token))
    |> validate_required(@token_required_fields)
    |> unique_constraint(:token_hash)
  end

  @doc """
  Marks an invitation as accepted by the trusted user and account ids.
  """
  @spec accept_changeset(t(), Ecto.UUID.t(), Ecto.UUID.t(), DateTime.t()) :: Ecto.Changeset.t()
  def accept_changeset(invitation, user_id, account_id, now) do
    invitation
    |> change(
      status: :accepted,
      accepted_at: now,
      accepted_user_id: user_id,
      accepted_account_id: account_id
    )
  end

  @doc """
  Marks an invitation as revoked.
  """
  @spec revoke_changeset(t()) :: Ecto.Changeset.t()
  def revoke_changeset(invitation), do: change(invitation, status: :revoked)

  @doc """
  Returns true when an invitation is pending and has not expired.

  ## Examples

      iex> expires_at = ~U[2026-07-16 12:01:00Z]
      iex> now = ~U[2026-07-16 12:00:00Z]
      iex> HouseSearch.Accounts.Invitation.usable?(%HouseSearch.Accounts.Invitation{status: :pending, expires_at: expires_at}, now)
      true
  """
  @spec usable?(t(), DateTime.t()) :: boolean()
  def usable?(%__MODULE__{status: :pending, expires_at: expires_at}, now) do
    DateTime.before?(now, expires_at)
  end

  def usable?(_, _), do: false

  @doc """
  Returns the stable reason an invitation cannot be accepted.
  """
  @spec unusable_reason(t()) :: :already_accepted | :revoked | :expired
  def unusable_reason(%__MODULE__{status: :accepted}), do: :already_accepted
  def unusable_reason(%__MODULE__{status: :revoked}), do: :revoked
  def unusable_reason(%__MODULE__{}), do: :expired

  @doc """
  Hashes an invitation token before persistence.
  """
  @spec hash_token(String.t()) :: binary()
  def hash_token(token) when is_binary(token), do: :crypto.hash(:sha256, token)

  @doc """
  Normalizes recipient email input.

  ## Examples

      iex> HouseSearch.Accounts.Invitation.normalize_email(" USER@Example.COM ")
      "user@example.com"
  """
  @spec normalize_email(String.t() | term()) :: String.t() | term()
  def normalize_email(email) when is_binary(email),
    do: email |> String.trim() |> String.downcase()

  def normalize_email(email), do: email
end
