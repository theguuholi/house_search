defmodule HouseSearch.Accounts.AccountTest do
  use HouseSearch.DataCase, async: true

  alias HouseSearch.Accounts.Account

  doctest Account

  test "changeset accepts account-owned fields" do
    changeset = Account.changeset(%Account{}, %{name: "Pilot House", timezone: "UTC"})

    assert changeset.valid?
    assert Ecto.Changeset.get_change(changeset, :name) == "Pilot House"
    assert Ecto.Changeset.get_change(changeset, :timezone) == "UTC"
  end

  test "changeset does not accept server-owned pilot start time" do
    now = DateTime.utc_now()
    changeset = Account.changeset(%Account{}, %{name: "Pilot House", pilot_started_at: now})

    assert changeset.valid?
    refute Ecto.Changeset.get_change(changeset, :pilot_started_at)
  end

  test "create_changeset stamps trusted pilot start time" do
    now = DateTime.utc_now()
    changeset = Account.create_changeset(%Account{}, %{name: "Pilot House"}, now)

    assert changeset.valid?
    assert Ecto.Changeset.get_change(changeset, :pilot_started_at) == now
  end

  test "changeset requires name" do
    changeset = Account.changeset(%Account{}, %{})

    refute changeset.valid?
    assert "can't be blank" in errors_on(changeset).name
  end
end
