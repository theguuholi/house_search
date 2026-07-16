defmodule HouseSearch.Accounts.BrokerListingTest do
  use HouseSearch.DataCase, async: false

  import HouseSearch.AccountsFixtures

  alias HouseSearch.Accounts
  alias HouseSearch.Accounts.Invitation
  alias HouseSearch.Repo

  setup do
    admin = admin_fixture()
    {:ok, _settings} = Accounts.update_pilot_settings(%{participant_limit: 200})

    %{admin: admin}
  end

  test "uses a 25-row default page and returns metadata", %{admin: admin} do
    invitations = create_invitations(admin, 26)

    assert {rows, %Flop.Meta{} = meta} = Accounts.list_brokers(%{})
    assert length(rows) == 25
    assert meta.current_page == 1
    assert meta.page_size == 25
    assert meta.total_count == 26
    assert meta.total_pages == 2
    assert meta.next_page == 2
    assert meta.previous_page == nil
    assert meta.has_next_page?
    refute meta.has_previous_page?
    assert Enum.all?(rows, &(&1 in invitations))
  end

  test "accepts the 100-row maximum and safely replaces oversized page sizes", %{admin: admin} do
    create_invitations(admin, 101)

    assert {rows, meta} = Accounts.list_brokers(%{"page_size" => "100"})
    assert length(rows) == 100
    assert meta.page_size == 100
    assert meta.total_count == 101
    assert meta.total_pages == 2

    assert {fallback_rows, fallback_meta} =
             Accounts.list_brokers(%{"page_size" => "101"})

    assert length(fallback_rows) == 25
    assert fallback_meta.page_size == 25
    assert fallback_meta.total_count == 101
    assert fallback_meta.total_pages == 5
  end

  test "applies the stable default order", %{admin: admin} do
    oldest = invitation_fixture(admin: admin, email: "oldest@example.com").invitation
    zulu = invitation_fixture(admin: admin, email: "zulu@example.com").invitation
    alpha = invitation_fixture(admin: admin, email: "alpha@example.com").invitation

    oldest_at = ~U[2026-07-15 12:00:00.000000Z]
    newest_at = ~U[2026-07-16 12:00:00.000000Z]
    set_inserted_at(oldest, oldest_at)
    set_inserted_at(zulu, newest_at)
    set_inserted_at(alpha, newest_at)

    assert {rows, _meta} = Accounts.list_brokers(%{})

    assert Enum.map(rows, & &1.email) == [
             "alpha@example.com",
             "zulu@example.com",
             "oldest@example.com"
           ]
  end

  test "q matches broker name or email without becoming a Flop filter", %{admin: admin} do
    named =
      invitation_fixture(
        admin: admin,
        email: "named@example.com",
        name: "Unique Magnolia"
      ).invitation

    emailed =
      invitation_fixture(
        admin: admin,
        email: "unique-orchid@example.com",
        name: "Email Match"
      ).invitation

    invitation_fixture(admin: admin, email: "unrelated@example.com", name: "Other Broker")

    assert {[name_match], name_meta} = Accounts.list_brokers(%{"q" => "  MAGNOLIA  "})
    assert name_match.id == named.id
    assert name_meta.total_count == 1
    assert name_meta.flop.filters == []

    assert {[email_match], email_meta} = Accounts.list_brokers(%{"q" => "ORCHID"})
    assert email_match.id == emailed.id
    assert email_meta.total_count == 1
    assert email_meta.flop.filters == []
  end

  test "supports approved ascending and descending orders", %{admin: admin} do
    invitation_fixture(admin: admin, email: "charlie@example.com", name: "Charlie")
    invitation_fixture(admin: admin, email: "alpha@example.com", name: "Alpha")
    invitation_fixture(admin: admin, email: "bravo@example.com", name: "Bravo")

    assert {ascending, ascending_meta} =
             Accounts.list_brokers(%{
               "order_by" => ["name"],
               "order_directions" => ["asc"]
             })

    assert Enum.map(ascending, & &1.name) == ["Alpha", "Bravo", "Charlie"]
    assert ascending_meta.flop.order_by == [:name, :id]
    assert ascending_meta.flop.order_directions == [:asc, :asc]

    assert {descending, descending_meta} =
             Accounts.list_brokers(%{
               "order_by" => ["name"],
               "order_directions" => ["desc"]
             })

    assert Enum.map(descending, & &1.name) == ["Charlie", "Bravo", "Alpha"]
    assert descending_meta.flop.order_by == [:name, :id]
    assert descending_meta.flop.order_directions == [:desc, :asc]
  end

  test "user-selected sorting stays deterministic across page boundaries when values tie", %{
    admin: admin
  } do
    invitations =
      for index <- 1..4 do
        invitation_fixture(
          admin: admin,
          email: "tied-#{index}@example.com",
          name: "Same Name"
        ).invitation
      end

    params = %{
      "page_size" => "2",
      "order_by" => ["name"],
      "order_directions" => ["asc"]
    }

    assert {first_page, first_meta} = params |> Map.put("page", "1") |> Accounts.list_brokers()

    assert {second_page, second_meta} =
             params |> Map.put("page", "2") |> Accounts.list_brokers()

    assert first_meta.flop.order_by == [:name, :id]
    assert first_meta.flop.order_directions == [:asc, :asc]
    assert second_meta.flop.order_by == [:name, :id]
    assert second_meta.flop.order_directions == [:asc, :asc]

    returned_ids = Enum.map(first_page ++ second_page, & &1.id)
    expected_ids = invitations |> Enum.map(& &1.id) |> Enum.sort()
    assert returned_ids == expected_ids
  end

  test "returns the requested page contents and metadata", %{admin: admin} do
    create_invitations(admin, 5)

    assert {rows, meta} =
             Accounts.list_brokers(%{
               "page" => "2",
               "page_size" => "2",
               "order_by" => ["email"],
               "order_directions" => ["asc"]
             })

    assert Enum.map(rows, & &1.email) == ["broker-003@example.com", "broker-004@example.com"]
    assert meta.current_page == 2
    assert meta.current_offset == 2
    assert meta.page_size == 2
    assert meta.total_count == 5
    assert meta.total_pages == 3
    assert meta.previous_page == 1
    assert meta.next_page == 3
    assert meta.has_previous_page?
    assert meta.has_next_page?
  end

  test "accepts only URL parameter maps at the context boundary" do
    assert_raise FunctionClauseError, fn ->
      Accounts.list_brokers(search: "broker", page: "2", per_page: "2")
    end
  end

  test "invalid page, page size, order field, and direction fall back without raising", %{
    admin: admin
  } do
    create_invitations(admin, 3)

    invalid_cases = [
      {%{"page" => "not-a-page"}, [:inserted_at, :email, :id], [:desc, :asc, :asc]},
      {%{"page_size" => "not-a-size"}, [:inserted_at, :email, :id], [:desc, :asc, :asc]},
      {%{"order_by" => ["not_a_field"]}, [:inserted_at, :email, :id], [:desc, :asc, :asc]},
      {%{"order_by" => ["name"], "order_directions" => ["sideways"]}, [:name, :id], [:asc, :asc]}
    ]

    for {params, expected_order_by, expected_directions} <- invalid_cases do
      assert {rows, %Flop.Meta{} = meta} = Accounts.list_brokers(params)
      assert length(rows) == 3
      assert meta.current_page == 1
      assert meta.page_size == 25
      assert meta.flop.order_by == expected_order_by
      assert meta.flop.order_directions == expected_directions
    end
  end

  defp create_invitations(admin, count) do
    for index <- 1..count do
      invitation_fixture(
        admin: admin,
        email: "broker-#{index |> Integer.to_string() |> String.pad_leading(3, "0")}@example.com",
        name: "Broker #{index}"
      ).invitation
    end
  end

  defp set_inserted_at(%Invitation{id: id}, inserted_at) do
    Invitation
    |> where([invitation], invitation.id == ^id)
    |> Repo.update_all(set: [inserted_at: inserted_at])
  end
end
