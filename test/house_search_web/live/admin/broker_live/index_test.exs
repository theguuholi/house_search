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

  test "IT-004 broker access is denied without exposing management rows or list metadata", %{
    conn: conn
  } do
    %{user: broker} = broker_fixture()
    invitation_fixture(email: "hidden-broker@example.com", name: "Hidden Broker")

    hostile_params = %{
      "q" => %{"malformed" => "query"},
      "page" => "999999999999999999999999",
      "page_size" => "100",
      "order_by" => ["email"],
      "order_directions" => ["desc"]
    }

    {:ok, lv, _html} =
      conn
      |> log_in_user(broker)
      |> live(~p"/admin/brokers?#{hostile_params}")

    assert has_element?(lv, "#admin-brokers", "Access denied")
    refute has_element?(lv, "#invite_form")
    refute has_element?(lv, "#invitations")
    refute has_element?(lv, "nav[aria-label='Broker invitations pages']")
    refute has_element?(lv, "#admin-brokers", "hidden-broker@example.com")
  end

  test "route params reproduce filtered, ordered, and paginated broker rows", %{conn: conn} do
    admin = admin_fixture()
    {:ok, _settings} = Accounts.update_pilot_settings(%{participant_limit: 20})

    invitation_fixture(admin: admin, email: "alpha@example.com", name: "Reference Alpha")
    invitation_fixture(admin: admin, email: "bravo@example.com", name: "Reference Bravo")
    invitation_fixture(admin: admin, email: "charlie@example.com", name: "Reference Charlie")
    invitation_fixture(admin: admin, email: "other@example.com", name: "Unrelated")

    params = %{
      "q" => "  reference  ",
      "page" => "2",
      "page_size" => "2",
      "order_by" => ["name"],
      "order_directions" => ["asc"]
    }

    {:ok, lv, _html} =
      conn
      |> log_in_user(admin)
      |> live(~p"/admin/brokers?#{params}")

    assert has_element?(lv, "#search_form input[name='search[q]'][value='reference']")
    assert has_element?(lv, "#invitations", "Reference Charlie")
    refute has_element?(lv, "#invitations", "Reference Alpha")
    refute has_element?(lv, "#invitations", "Unrelated")

    assert has_element?(
             lv,
             "nav[aria-label='Broker invitations pages'] [aria-current='page']",
             "2"
           )

    refute has_element?(lv, "#invitations", "usage")
    refute has_element?(lv, "#invitations", "case")
  end

  test "search trims q, preserves ordering and page size, and resets the page", %{conn: conn} do
    admin = admin_fixture()
    {:ok, _settings} = Accounts.update_pilot_settings(%{participant_limit: 20})

    invitation_fixture(admin: admin, email: "alpha@example.com", name: "Alpha Match")
    invitation_fixture(admin: admin, email: "bravo@example.com", name: "Bravo Match")
    invitation_fixture(admin: admin, email: "charlie@example.com", name: "Charlie Match")

    initial_params = %{
      "page" => "2",
      "page_size" => "2",
      "order_by" => ["name"],
      "order_directions" => ["desc"]
    }

    {:ok, lv, _html} =
      conn
      |> log_in_user(admin)
      |> live(~p"/admin/brokers?#{initial_params}")

    lv
    |> form("#search_form", search: %{q: "  Alpha  "})
    |> render_submit()

    patched_path = assert_patch(lv)
    query = decoded_query(patched_path)

    assert query["q"] == "Alpha"
    assert query["page_size"] == "2"
    assert query["order_by"] == ["name", "id"]
    assert query["order_directions"] == ["desc", "asc"]
    refute Map.has_key?(query, "page")
    assert has_element?(lv, "#invitations", "Alpha Match")
    refute has_element?(lv, "#invitations", "Bravo Match")
  end

  test "sort header patches the URL and reorders broker rows", %{conn: conn} do
    admin = admin_fixture()
    {:ok, _settings} = Accounts.update_pilot_settings(%{participant_limit: 20})

    invitation_fixture(admin: admin, email: "first@example.com", name: "Zulu Broker")
    invitation_fixture(admin: admin, email: "second@example.com", name: "Alpha Broker")

    params = %{
      "order_by" => ["email"],
      "order_directions" => ["asc"]
    }

    {:ok, lv, _html} =
      conn
      |> log_in_user(admin)
      |> live(~p"/admin/brokers?#{params}")

    lv
    |> element("#invitations thead th a", "Broker, sort ascending")
    |> render_click()

    query = lv |> assert_patch() |> decoded_query()

    assert List.first(query["order_by"]) == "name"
    assert List.first(query["order_directions"]) == "asc"
    assert has_element?(lv, "#invitations tr:first-child", "Alpha Broker")
    assert has_element?(lv, "#invitations th[aria-sort='ascending']", "Broker")
  end

  test "pagination patches the URL and direct navigation reproduces the requested page", %{
    conn: conn
  } do
    admin = admin_fixture()
    {:ok, _settings} = Accounts.update_pilot_settings(%{participant_limit: 20})

    for index <- 1..5 do
      invitation_fixture(
        admin: admin,
        email: "page-#{index |> Integer.to_string() |> String.pad_leading(3, "0")}@example.com",
        name: "Page Broker #{index}"
      )
    end

    params = %{
      "page_size" => "2",
      "order_by" => ["email"],
      "order_directions" => ["asc"]
    }

    authenticated_conn = log_in_user(conn, admin)
    {:ok, lv, _html} = live(authenticated_conn, ~p"/admin/brokers?#{params}")

    lv
    |> element("nav[aria-label='Broker invitations pages'] a[rel='next']")
    |> render_click()

    patched_path = assert_patch(lv)

    assert decoded_query(patched_path)["page"] == "2"
    assert has_element?(lv, "#invitations", "page-003@example.com")
    assert has_element?(lv, "#invitations", "page-004@example.com")
    refute has_element?(lv, "#invitations", "page-001@example.com")

    {:ok, reproduced, _html} = live(authenticated_conn, patched_path)

    assert has_element?(reproduced, "#invitations", "page-003@example.com")
    assert has_element?(reproduced, "#invitations", "page-004@example.com")
    refute has_element?(reproduced, "#invitations", "page-001@example.com")
  end

  test "successful invite retains the current search and order state", %{conn: conn} do
    admin = admin_fixture()
    {:ok, _settings} = Accounts.update_pilot_settings(%{participant_limit: 20})
    invitation_fixture(admin: admin, email: "retained-a@example.com", name: "Retained A")

    params = %{
      "q" => "retained",
      "order_by" => ["email"],
      "order_directions" => ["desc"]
    }

    {:ok, lv, _html} =
      conn
      |> log_in_user(admin)
      |> live(~p"/admin/brokers?#{params}")

    lv
    |> form("#invite_form",
      invitation: %{email: "retained-z@example.com", name: "Retained Z"}
    )
    |> render_submit()

    patched_path = assert_patch(lv)

    assert_preserved_list_state(patched_path, "retained", "email", "desc")
    assert has_element?(lv, "#invitations", "retained-z@example.com")
    assert has_element?(lv, "#flash-info", "Invitation ready")
  end

  test "successful revoke retains the current search and order state", %{conn: conn} do
    admin = admin_fixture()
    {:ok, _settings} = Accounts.update_pilot_settings(%{participant_limit: 20})

    %{invitation: invitation} =
      invitation_fixture(
        admin: admin,
        email: "retained-revoke@example.com",
        name: "Retained Revoke"
      )

    params = %{
      "q" => "retained-revoke",
      "order_by" => ["email"],
      "order_directions" => ["desc"]
    }

    {:ok, lv, _html} =
      conn
      |> log_in_user(admin)
      |> live(~p"/admin/brokers?#{params}")

    lv
    |> element("button[phx-click='revoke'][phx-value-id='#{invitation.id}']")
    |> render_click()

    patched_path = assert_patch(lv)

    assert_preserved_list_state(patched_path, "retained-revoke", "email", "desc")
    assert has_element?(lv, "#invitations", "retained-revoke@example.com")
    assert has_element?(lv, "#invitations", "revoked")
    assert has_element?(lv, "#flash-info", "Invitation revoked")
  end

  defp assert_preserved_list_state(path, q, order_by, order_direction) do
    query = decoded_query(path)

    assert query["q"] == q
    assert List.first(query["order_by"]) == order_by
    assert List.first(query["order_directions"]) == order_direction
  end

  defp decoded_query(path) do
    path
    |> URI.parse()
    |> Map.get(:query, "")
    |> Plug.Conn.Query.decode()
  end
end
