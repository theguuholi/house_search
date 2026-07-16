defmodule HouseSearchWeb.Admin.BrokerLive.IndexTest do
  use HouseSearchWeb.ConnCase, async: false

  import HouseSearch.AccountsFixtures
  import Phoenix.LiveViewTest

  alias HouseSearch.Accounts

  test "IT-001 invalid email renders correction and inserts nothing", %{conn: conn} do
    admin = admin_fixture()
    {:ok, lv, _html} = conn |> log_in_user(admin) |> live(~p"/admin/brokers")

    lv
    |> form("#invite_form", invitation: %{email: "bad-email", name: "Ana"})
    |> render_submit()

    assert has_element?(lv, "#invite_form p", "must have the @ sign and no spaces")
    assert has_element?(lv, "#invitations-empty")
    refute has_element?(lv, "#invitations", "bad-email")
  end

  test "IT-002 blank name or email renders required errors and inserts nothing", %{conn: conn} do
    admin = admin_fixture()
    {:ok, lv, _html} = conn |> log_in_user(admin) |> live(~p"/admin/brokers")

    lv
    |> form("#invite_form", invitation: %{email: "", name: ""})
    |> render_submit()

    assert has_element?(lv, "#invite_form p", "can't be blank")
    assert has_element?(lv, "#invitations-empty")
    refute has_element?(lv, "#invitations td")
  end

  test "IT-003 participant limit renders limit and inserts nothing", %{conn: conn} do
    admin = admin_fixture()
    {:ok, _settings} = Accounts.update_pilot_settings(%{participant_limit: 0})
    {:ok, lv, _html} = conn |> log_in_user(admin) |> live(~p"/admin/brokers")

    email = unique_user_email()

    lv
    |> form("#invite_form", invitation: %{email: email, name: "Ana"})
    |> render_submit()

    assert has_element?(lv, "#flash-error", "Pilot participant limit reached")
    assert has_element?(lv, "#invitations-empty")
    refute has_element?(lv, "#invitations", email)
  end

  test "IT-004 broker access is denied without exposing management rows", %{conn: conn} do
    %{user: broker} = broker_fixture()
    invitation_fixture(email: "hidden-broker@example.com", name: "Hidden Broker")

    {:ok, lv, _html} = conn |> log_in_user(broker) |> live(~p"/admin/brokers")

    assert has_element?(lv, "#admin-brokers", "Access denied")
    refute has_element?(lv, "#invite_form")

    render_change(lv, :search, %{"search" => %{"q" => "hidden"}})

    assert has_element?(lv, "#admin-brokers", "Access denied")
    refute has_element?(lv, "#invitations", "hidden-broker@example.com")
  end

  test "IT-010 search and pagination return requested broker rows without usage details", %{
    conn: conn
  } do
    admin = admin_fixture()
    {:ok, _settings} = Accounts.update_pilot_settings(%{participant_limit: 40})

    for index <- 1..30 do
      invitation_fixture(
        admin: admin,
        email: "broker#{index}@example.com",
        name: "Broker #{index}"
      )
    end

    {:ok, lv, _html} =
      conn
      |> log_in_user(admin)
      |> live(~p"/admin/brokers?q=broker2&page=1")

    assert has_element?(lv, "#invitations", "broker2@example.com")
    refute has_element?(lv, "#invitations", "usage")
    refute has_element?(lv, "#invitations", "case")
  end
end
