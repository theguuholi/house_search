defmodule HouseSearch.Accounts.PilotSettings do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "pilot_settings" do
    field :participant_limit, :integer, default: 5
    field :lock_version, :integer, default: 1

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(settings, attrs) do
    settings
    |> cast(attrs, [:participant_limit])
    |> validate_required([:participant_limit])
    |> validate_number(:participant_limit, greater_than_or_equal_to: 0)
    |> optimistic_lock(:lock_version)
  end
end
