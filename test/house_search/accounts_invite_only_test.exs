defmodule HouseSearch.AccountsInviteOnlyTest do
  use HouseSearch.DataCase, async: false

  import HouseSearch.AccountsFixtures

  alias HouseSearch.Accounts
  alias HouseSearch.Accounts.Account
  alias HouseSearch.Accounts.Authorization
  alias HouseSearch.Accounts.Invitation
  alias HouseSearch.Accounts.Membership
  alias HouseSearch.Repo

  describe "invitation contract" do
    test "UT-001 invalid invitation email returns an email format error" do
      changeset =
        Invitation.changeset(%Invitation{}, %{
          email: "not-an-email",
          name: "Ana Broker",
          inviter_id: Ecto.UUID.generate(),
          expires_at: DateTime.utc_now()
        })

      refute changeset.valid?
      assert "must have the @ sign and no spaces" in errors_on(changeset).email
    end

    test "UT-002 blank name or email reports required fields" do
      changeset =
        Invitation.changeset(%Invitation{}, %{
          email: "",
          name: "",
          inviter_id: Ecto.UUID.generate(),
          expires_at: DateTime.utc_now()
        })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).email
      assert "can't be blank" in errors_on(changeset).name
    end

    test "UT-003 pilot participant limit counts active users and pending invitations" do
      admin = admin_fixture()
      {:ok, _settings} = Accounts.update_pilot_settings(%{participant_limit: 0})

      assert {:error, :pilot_limit_reached} =
               Accounts.invite_broker(admin, %{email: unique_user_email(), name: "Ana"}, & &1)
    end

    test "UT-004 usable is true before expiry and false at expiry" do
      expires_at = DateTime.utc_now() |> DateTime.add(60, :second) |> DateTime.truncate(:second)
      invitation = %Invitation{status: :pending, expires_at: expires_at}

      assert Invitation.usable?(invitation, DateTime.add(expires_at, -1, :second))
      refute Invitation.usable?(invitation, expires_at)
    end

    test "UT-005 usable maps accepted and revoked replay states" do
      expires_at = DateTime.utc_now() |> DateTime.add(60, :second) |> DateTime.truncate(:second)

      accepted = %Invitation{status: :accepted, expires_at: expires_at}
      revoked = %Invitation{status: :revoked, expires_at: expires_at}

      refute Invitation.usable?(accepted, DateTime.utc_now())
      refute Invitation.usable?(revoked, DateTime.utc_now())
      assert Invitation.unusable_reason(accepted) == :already_accepted
      assert Invitation.unusable_reason(revoked) == :revoked
    end
  end

  describe "authorization contract" do
    test "UT-006 active member can read and mutate own account resources" do
      %{user: user, account: account} = broker_fixture()

      assert :ok = Authorization.authorize(user, :read, %{account_id: account.id})
      assert :ok = Authorization.authorize(user, :mutate, %{account_id: account.id})
    end

    test "UT-007 system administrator can use cross-account admin operations" do
      admin = admin_fixture()

      assert :ok = Authorization.authorize(admin, :invite_broker, :admin)
      assert :ok = Authorization.authorize(admin, :manage_brokers, :admin)
    end

    test "UT-008 foreign account access returns not found" do
      %{user: user} = broker_fixture()
      changeset = Account.changeset(%Account{}, %{name: "Foreign"})
      foreign_account = Repo.insert!(changeset)

      assert {:error, :not_found} =
               Authorization.authorize(user, :read, %{account_id: foreign_account.id})
    end

    test "UT-009 non-admin and suspended actors receive stable tagged errors" do
      admin = admin_fixture()
      %{user: user} = broker_fixture(admin: admin)

      assert {:error, :unauthorized} = Authorization.authorize(user, :invite_broker, :admin)
      {:ok, suspended} = Accounts.suspend_user(admin, user)

      assert {:error, :suspended} =
               Authorization.authorize(suspended, :mutate, %{account_id: Ecto.UUID.generate()})
    end

    test "UT-010 suspension invalidates mutation permission for existing actor" do
      admin = admin_fixture()
      %{user: user, account: account} = broker_fixture(admin: admin)
      actor = %{user_id: user.id, account_id: account.id}

      assert :ok = Accounts.authorize(actor, :mutate, %{account_id: account.id})
      {:ok, _user} = Accounts.suspend_user(admin, user)

      assert {:error, :suspended} = Accounts.authorize(actor, :mutate, %{account_id: account.id})
    end
  end

  test "IT-005 concurrent duplicate invitations leave one pending row" do
    admin = admin_fixture()
    email = "broker@example.com"

    results =
      1..2
      |> Enum.map(fn _ ->
        Task.async(fn ->
          Ecto.Adapters.SQL.Sandbox.allow(Repo, self(), self())
          Accounts.invite_broker(admin, %{email: email, name: "Ana"}, & &1)
        end)
      end)
      |> Task.await_many()

    assert Enum.all?(results, &match?({:ok, %Invitation{}}, &1))

    invitation_count =
      Invitation
      |> where([i], i.email == ^email)
      |> Repo.aggregate(:count)

    assert invitation_count == 1
  end

  test "IT-006 and IT-007 activation resumes and replay creates no duplicates" do
    %{token: token} = invitation_fixture(email: "ana@example.com")

    assert {:ok, %{user: user, account: account}} =
             Accounts.accept_invitation(token, %{
               password: valid_user_password(),
               password_confirmation: valid_user_password()
             })

    user_count =
      Accounts.User
      |> where([u], u.email == "ana@example.com")
      |> Repo.aggregate(:count)

    membership_count =
      Membership
      |> where([m], m.user_id == ^user.id and m.account_id == ^account.id)
      |> Repo.aggregate(:count)

    assert user_count == 1
    assert membership_count == 1

    assert {:error, :already_accepted} =
             Accounts.accept_invitation(token, %{password: valid_user_password()})
  end
end
