defmodule HouseSearch.Accounts.Membership do
  @moduledoc """
  Represents a user's membership in an account.

  Memberships connect `HouseSearch.Accounts.User` rows to
  `HouseSearch.Accounts.Account` rows and store the user's account-local role.
  See `HouseSearch.Accounts`.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias HouseSearch.Accounts.Account
  alias HouseSearch.Accounts.User

  @roles ~w/broker owner/a
  @trusted_required_fields [:account_id, :user_id, :role]

  @typedoc "Account-local membership role."
  @type role :: :broker | :owner

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          account_id: Ecto.UUID.t() | nil,
          account: Account.t() | Ecto.Association.NotLoaded.t() | nil,
          user_id: Ecto.UUID.t() | nil,
          user: User.t() | Ecto.Association.NotLoaded.t() | nil,
          role: role(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "memberships" do
    belongs_to :account, Account
    belongs_to :user, User
    field :role, Ecto.Enum, values: @roles, default: :broker

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Builds a membership changeset from trusted account and user ids.

  ## Examples

      iex> account_id = Ecto.UUID.generate()
      iex> user_id = Ecto.UUID.generate()
      iex> changeset = HouseSearch.Accounts.Membership.changeset(%HouseSearch.Accounts.Membership{}, account_id, user_id, :owner)
      iex> Ecto.Changeset.get_change(changeset, :role)
      :owner
  """
  @spec changeset(t(), Ecto.UUID.t(), Ecto.UUID.t(), role()) :: Ecto.Changeset.t()
  def changeset(membership, account_id, user_id, role \\ :broker) do
    membership
    |> change(account_id: account_id, user_id: user_id, role: role)
    |> validate_required(@trusted_required_fields)
    |> unique_constraint([:account_id, :user_id])
  end
end
