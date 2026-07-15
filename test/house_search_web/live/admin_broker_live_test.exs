defmodule HouseSearchWeb.AdminBrokerLiveTest do
  use HouseSearchWeb.ConnCase, async: false

  import HouseSearch.AccountsFixtures
  import Phoenix.LiveViewTest

  alias HouseSearch.Accounts
  alias HouseSearch.Accounts.Invitation
  alias HouseSearch.Repo

  test "IT-001 invalid email renders correction and inserts nothing", %{conn: conn} do
    admin = admin_fixture()
    {:ok, lv, _html} = conn |> log_in_user(admin) |> live(~p"/admin/brokers")

    html =
      lv
      |> form("#invite_form", invitation: %{email: "bad-email", name: "Ana"})
      |> render_submit()

    assert html =~ "must have the @ sign and no spaces"
    assert Repo.aggregate(Invitation, :count) == 0
  end

  test "IT-002 blank name or email renders required errors and inserts nothing", %{conn: conn} do
    admin = admin_fixture()
    {:ok, lv, _html} = conn |> log_in_user(admin) |> live(~p"/admin/brokers")

    html =
      lv
      |> form("#invite_form", invitation: %{email: "", name: ""})
      |> render_submit()

    assert html =~ "can&#39;t be blank"
    assert Repo.aggregate(Invitation, :count) == 0
  end

  test "IT-003 participant limit renders limit and inserts nothing", %{conn: conn} do
    admin = admin_fixture()
    {:ok, _settings} = Accounts.update_pilot_settings(%{participant_limit: 0})
    {:ok, lv, _html} = conn |> log_in_user(admin) |> live(~p"/admin/brokers")

    html =
      lv
      |> form("#invite_form", invitation: %{email: unique_user_email(), name: "Ana"})
      |> render_submit()

    assert html =~ "Pilot participant limit reached"
    assert Repo.aggregate(Invitation, :count) == 0
  end

  test "IT-004 broker access is denied without exposing management rows", %{conn: conn} do
    %{user: broker} = broker_fixture()

    {:ok, _lv, html} = conn |> log_in_user(broker) |> live(~p"/admin/brokers")

    assert html =~ "Access denied"
    refute html =~ "invite_form"
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

    {:ok, _lv, html} =
      conn
      |> log_in_user(admin)
      |> live(~p"/admin/brokers?q=broker2&page=1")

    assert html =~ "broker2@example.com"
    refute html =~ "usage"
    refute html =~ "case"
  end
end
