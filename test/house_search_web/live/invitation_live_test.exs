defmodule HouseSearchWeb.InvitationLiveTest do
  use HouseSearchWeb.ConnCase, async: false

  import HouseSearch.AccountsFixtures
  import Phoenix.LiveViewTest

  alias HouseSearch.Accounts
  alias HouseSearch.Accounts.Invitation
  alias HouseSearch.Repo

  test "IT-006 activation resumes and completes one user account membership", %{conn: conn} do
    %{token: token} = invitation_fixture(email: "ana@example.com")

    {:ok, lv, _html} = live(conn, ~p"/invitations/#{token}")
    assert has_element?(lv, "h1", "Activate pilot access")

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

    {:ok, lv, _html} = live(conn, ~p"/invitations/#{token}")

    assert has_element?(lv, "p", "This invitation has already been accepted.")
    assert has_element?(lv, "a[href='/users/log_in']", "Log in")
    assert Accounts.get_user!(user.id)
  end

  test "IT-008 signed-in different identity must sign out before activation", %{conn: conn} do
    other = user_fixture(email: "other@example.com")
    %{token: token} = invitation_fixture(email: "broker@example.com")

    {:ok, lv, _html} = conn |> log_in_user(other) |> live(~p"/invitations/#{token}")

    assert has_element?(
             lv,
             "p",
             "Sign out and open this invitation with the matching email address."
           )
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

    {:ok, expired_lv, _html} = live(conn, ~p"/invitations/#{expired_token}")
    {:ok, revoked_lv, _html} = live(conn, ~p"/invitations/#{revoked_token}")
    {:ok, accepted_lv, _html} = live(conn, ~p"/invitations/#{accepted_token}")

    assert has_element?(expired_lv, "p", "This invitation has expired.")
    assert has_element?(revoked_lv, "p", "This invitation is no longer available.")
    assert has_element?(accepted_lv, "p", "This invitation has already been accepted.")
  end
end
