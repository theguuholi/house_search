defmodule HouseSearch.Accounts.InvitationTest do
  use HouseSearch.DataCase, async: true

  alias HouseSearch.Accounts.Invitation

  doctest Invitation

  test "changeset normalizes email and stamps trusted fields" do
    inviter_id = Ecto.UUID.generate()
    expires_at = DateTime.utc_now()

    changeset =
      Invitation.changeset(
        %Invitation{},
        %{email: " BROKER@Example.COM ", name: "Ana Broker", status: :accepted},
        inviter_id,
        expires_at
      )

    assert changeset.valid?
    assert Ecto.Changeset.get_change(changeset, :email) == "broker@example.com"
    assert Ecto.Changeset.get_change(changeset, :inviter_id) == inviter_id
    assert Ecto.Changeset.get_change(changeset, :expires_at) == expires_at
    refute Ecto.Changeset.get_change(changeset, :status)
  end

  test "changeset validates required recipient fields" do
    changeset = Invitation.changeset(%Invitation{}, %{}, Ecto.UUID.generate(), DateTime.utc_now())

    refute changeset.valid?
    assert "can't be blank" in errors_on(changeset).email
    assert "can't be blank" in errors_on(changeset).name
  end

  test "token_changeset stores the token hash" do
    changeset = Invitation.token_changeset(%Invitation{}, "secret-token")

    assert changeset.valid?
    assert Ecto.Changeset.get_change(changeset, :token) == "secret-token"

    assert Ecto.Changeset.get_change(changeset, :token_hash) ==
             Invitation.hash_token("secret-token")
  end

  test "accept_changeset changes only acceptance fields" do
    user_id = Ecto.UUID.generate()
    account_id = Ecto.UUID.generate()
    now = DateTime.utc_now()

    changeset = Invitation.accept_changeset(%Invitation{}, user_id, account_id, now)

    assert Ecto.Changeset.get_change(changeset, :status) == :accepted
    assert Ecto.Changeset.get_change(changeset, :accepted_user_id) == user_id
    assert Ecto.Changeset.get_change(changeset, :accepted_account_id) == account_id
    assert Ecto.Changeset.get_change(changeset, :accepted_at) == now
  end

  test "usable? covers pending and non-pending states" do
    expires_at = DateTime.utc_now() |> DateTime.add(60, :second)

    assert Invitation.usable?(
             %Invitation{status: :pending, expires_at: expires_at},
             DateTime.utc_now()
           )

    refute Invitation.usable?(
             %Invitation{status: :accepted, expires_at: expires_at},
             DateTime.utc_now()
           )
  end
end
