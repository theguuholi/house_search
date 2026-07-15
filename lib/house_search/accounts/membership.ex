defmodule HouseSearch.Accounts.Membership do
  use Ecto.Schema

  import Ecto.Changeset

  alias HouseSearch.Accounts.Account
  alias HouseSearch.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "memberships" do
    belongs_to :account, Account
    belongs_to :user, User
    field :role, Ecto.Enum, values: [:broker, :owner], default: :broker

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:account_id, :user_id, :role])
    |> validate_required([:account_id, :user_id, :role])
    |> unique_constraint([:account_id, :user_id])
  end
end
