defmodule HouseSearch.Accounts.Invitation do
  use Ecto.Schema

  import Ecto.Changeset

  alias HouseSearch.Accounts.Account
  alias HouseSearch.Accounts.User

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

  def token_changeset(invitation, token) do
    invitation
    |> change(token: token, token_hash: hash_token(token))
    |> validate_required([:token_hash])
    |> unique_constraint(:token_hash)
  end

  def accept_changeset(invitation, user_id, account_id, now) do
    invitation
    |> change(
      status: :accepted,
      accepted_at: now,
      accepted_user_id: user_id,
      accepted_account_id: account_id
    )
  end

  def revoke_changeset(invitation), do: change(invitation, status: :revoked)

  def usable?(%__MODULE__{status: :pending, expires_at: expires_at}, now) do
    DateTime.before?(now, expires_at)
  end

  def usable?(_, _), do: false

  def unusable_reason(%__MODULE__{status: :accepted}), do: :already_accepted
  def unusable_reason(%__MODULE__{status: :revoked}), do: :revoked
  def unusable_reason(%__MODULE__{}), do: :expired

  def hash_token(token) when is_binary(token), do: :crypto.hash(:sha256, token)

  def normalize_email(email) when is_binary(email),
    do: email |> String.trim() |> String.downcase()

  def normalize_email(email), do: email
end
