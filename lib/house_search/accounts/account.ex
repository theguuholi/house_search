defmodule HouseSearch.Accounts.Account do
  @moduledoc """
  Represents a broker account in the invite-only pilot.

  Accounts group broker-owned resources and memberships. See
  `HouseSearch.Accounts` and `HouseSearch.Accounts.Membership`.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @statuses ~w/active suspended/a
  @fields [:status, :timezone]
  @required_fields [:name]
  @pilot_required_fields [:pilot_started_at]

  @typedoc "Account lifecycle state."
  @type status :: :active | :suspended

  @typedoc "IANA timezone name used for account-local scheduling."
  @type timezone :: String.t()

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          name: String.t() | nil,
          status: status(),
          timezone: timezone(),
          pilot_started_at: DateTime.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "accounts" do
    field :name, :string
    field :status, Ecto.Enum, values: @statuses, default: :active
    field :timezone, :string, default: "America/Sao_Paulo"
    field :pilot_started_at, :utc_datetime_usec

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Builds a changeset for account-owned editable fields.

  ## Examples

      iex> changeset = HouseSearch.Accounts.Account.changeset(%HouseSearch.Accounts.Account{}, %{name: " Pilot House "})
      iex> changeset.valid?
      true
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(account, attrs) do
    account
    |> cast(attrs, @fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> validate_length(:name, min: 1, max: 160)
  end

  @doc """
  Builds a creation changeset and stamps the trusted pilot start time.

  ## Examples

      iex> now = ~U[2026-07-16 12:00:00Z]
      iex> changeset = HouseSearch.Accounts.Account.create_changeset(%HouseSearch.Accounts.Account{}, %{name: "Pilot House"}, now)
      iex> Ecto.Changeset.get_change(changeset, :pilot_started_at)
      ~U[2026-07-16 12:00:00Z]
  """
  @spec create_changeset(t(), map(), DateTime.t()) :: Ecto.Changeset.t()
  def create_changeset(account, attrs, %DateTime{} = pilot_started_at) do
    account
    |> changeset(attrs)
    |> put_change(:pilot_started_at, pilot_started_at)
    |> validate_required(@pilot_required_fields)
  end
end
