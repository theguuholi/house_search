defmodule HouseSearchWeb.InvitationLiveTest do
  use HouseSearchWeb.ConnCase, async: false

  import Ecto.Query
  import HouseSearch.AccountsFixtures
  import Phoenix.LiveViewTest

  alias HouseSearch.Accounts
  alias HouseSearch.Accounts.Invitation
  alias HouseSearch.Repo

  test "IT-006 activation resumes and completes one user account membership", %{conn: conn} do
    %{token: token} = invitation_fixture(email: "ana@example.com")

    {:ok, lv, html} = live(conn, ~p"/invitations/#{token}")
    assert html =~ "Activate pilot access"

    {:ok, _conn} =
      lv
      |> form("#activation_form",
        user: %{
          password: valid_user_password(),
          password_confirmation: valid_user_password()
        }
      )
      |> render_submit()
      |> follow_redirect(conn, "/users/log_in?_action=password_updated&email=ana%40example.com")

    assert Accounts.get_user_by_email("ana@example.com")
  end

  test "IT-007 accepted invitation replay directs to login without duplicates", %{conn: conn} do
    %{token: token} = invitation_fixture(email: "ana@example.com")

    {:ok, %{user: user}} =
      Accounts.accept_invitation(token, %{
        password: valid_user_password(),
        password_confirmation: valid_user_password()
      })

    {:ok, _lv, html} = live(conn, ~p"/invitations/#{token}")

    assert html =~ "already been accepted"
    assert html =~ "Log in"

    user_count =
      Accounts.User
      |> where([u], u.id == ^user.id)
      |> Repo.aggregate(:count)

    assert user_count == 1
  end

  test "IT-008 signed-in different identity must sign out before activation", %{conn: conn} do
    other = user_fixture(email: "other@example.com")
    %{token: token} = invitation_fixture(email: "broker@example.com")

    {:ok, _lv, html} = conn |> log_in_user(other) |> live(~p"/invitations/#{token}")

    assert html =~ "Sign out and open this invitation with the matching email address"
  end

  test "IT-009 expired revoked and accepted tokens render generic states", %{conn: conn} do
    %{invitation: expired, token: expired_token} =
      invitation_fixture(email: "expired@example.com")

    %{invitation: revoked, token: revoked_token} =
      invitation_fixture(email: "revoked@example.com")

    %{token: accepted_token} = invitation_fixture(email: "accepted@example.com")

    expired
    |> Ecto.Changeset.change(expires_at: DateTime.add(DateTime.utc_now(), -1, :second))
    |> Repo.update!()

    revoked
    |> Invitation.revoke_changeset()
    |> Repo.update!()

    {:ok, _} =
      Accounts.accept_invitation(accepted_token, %{
        password: valid_user_password(),
        password_confirmation: valid_user_password()
      })

    {:ok, _lv, expired_html} = live(conn, ~p"/invitations/#{expired_token}")
    {:ok, _lv, revoked_html} = live(conn, ~p"/invitations/#{revoked_token}")
    {:ok, _lv, accepted_html} = live(conn, ~p"/invitations/#{accepted_token}")

    assert expired_html =~ "expired"
    assert revoked_html =~ "no longer available"
    assert accepted_html =~ "already been accepted"
  end
end
