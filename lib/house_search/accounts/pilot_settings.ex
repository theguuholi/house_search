defmodule HouseSearch.Accounts.PilotSettings do
  @moduledoc """
  Stores global invite-only pilot limits.

  The singleton row controls broker invitation capacity. See
  `HouseSearch.Accounts`.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @fields []
  @required_fields [:participant_limit]

  @typedoc "Maximum active member and pending invitation count for the pilot."
  @type participant_limit :: non_neg_integer()

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          participant_limit: participant_limit(),
          lock_version: pos_integer(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "pilot_settings" do
    field :participant_limit, :integer, default: 5
    field :lock_version, :integer, default: 1

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Builds a changeset for updating pilot capacity.

  ## Examples

      iex> changeset = HouseSearch.Accounts.PilotSettings.changeset(%HouseSearch.Accounts.PilotSettings{}, %{participant_limit: 3})
      iex> Ecto.Changeset.get_change(changeset, :participant_limit)
      3
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(settings, attrs) do
    settings
    |> cast(attrs, @fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> validate_number(:participant_limit, greater_than_or_equal_to: 0)
    |> optimistic_lock(:lock_version)
  end
end
