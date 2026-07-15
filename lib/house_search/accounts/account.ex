defmodule HouseSearch.Accounts.Account do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accounts" do
    field :name, :string
    field :status, Ecto.Enum, values: [:active, :suspended], default: :active
    field :timezone, :string, default: "America/Sao_Paulo"
    field :pilot_started_at, :utc_datetime_usec

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(account, attrs) do
    account
    |> cast(attrs, [:name, :status, :timezone, :pilot_started_at])
    |> validate_required([:name, :status, :timezone])
  end
end
