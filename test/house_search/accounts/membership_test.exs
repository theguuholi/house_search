defmodule HouseSearch.Accounts.MembershipTest do
  use HouseSearch.DataCase, async: true

  alias HouseSearch.Accounts.Membership

  doctest Membership

  test "changeset stamps trusted account and user ids" do
    account_id = Ecto.UUID.generate()
    user_id = Ecto.UUID.generate()

    changeset = Membership.changeset(%Membership{}, account_id, user_id, :owner)

    assert changeset.valid?
    assert Ecto.Changeset.get_change(changeset, :account_id) == account_id
    assert Ecto.Changeset.get_change(changeset, :user_id) == user_id
    assert Ecto.Changeset.get_change(changeset, :role) == :owner
  end

  test "changeset defaults role to broker" do
    changeset = Membership.changeset(%Membership{}, Ecto.UUID.generate(), Ecto.UUID.generate())

    assert changeset.valid?
    assert Ecto.Changeset.get_field(changeset, :role) == :broker
  end
end
