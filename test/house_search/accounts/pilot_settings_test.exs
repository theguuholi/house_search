defmodule HouseSearch.Accounts.PilotSettingsTest do
  use HouseSearch.DataCase, async: true

  alias HouseSearch.Accounts.PilotSettings

  doctest PilotSettings

  test "changeset accepts non-negative participant limit" do
    changeset = PilotSettings.changeset(%PilotSettings{}, %{participant_limit: 2})

    assert changeset.valid?
    assert Ecto.Changeset.get_change(changeset, :participant_limit) == 2
  end

  test "changeset rejects negative participant limit" do
    changeset = PilotSettings.changeset(%PilotSettings{}, %{participant_limit: -1})

    refute changeset.valid?
    assert "must be greater than or equal to 0" in errors_on(changeset).participant_limit
  end
end
