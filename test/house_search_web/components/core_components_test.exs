defmodule HouseSearchWeb.CoreComponentsTest do
  use HouseSearchWeb.ConnCase, async: true
  use Phoenix.Component

  import Phoenix.LiveViewTest

  alias HouseSearch.Accounts.Invitation
  alias HouseSearchWeb.CoreComponents

  describe "table/1" do
    test "preserves plain table rendering" do
      html =
        render_component(&plain_table/1, %{
          rows: [%{id: "person-1", name: "Ada", email: "ada@example.com"}]
        })

      document = parse_fragment!(html)

      assert document |> Floki.find("thead th") |> Enum.map(&Floki.text/1) == ["Name", "Email"]
      assert document |> Floki.find("tbody#people tr") |> length() == 1

      assert document |> Floki.find("tbody td") |> Enum.map(&normalized_text/1) == [
               "Ada",
               "ada@example.com"
             ]

      assert Floki.find(document, "thead a") == []
    end

    test "sortable column links name the next direction and preserve unrelated query params" do
      html =
        render_component(&sortable_table/1, %{
          meta: meta(order_by: [:email], order_directions: [:desc]),
          path: "/admin/brokers?q=ada",
          rows: [%{id: "person-1", name: "Ada", email: "ada@example.com"}]
        })

      document = parse_fragment!(html)
      [link] = Floki.find(document, "th a")

      assert normalized_text(link) == "Name, sort ascending"
      assert Floki.attribute(link, "data-phx-link") == ["patch"]

      assert link
             |> Floki.attribute("href")
             |> List.first()
             |> decoded_query()
             |> Map.take(["q", "order_by", "order_directions"]) == %{
               "q" => "ada",
               "order_by" => ["name", "email"],
               "order_directions" => ["asc", "desc"]
             }
    end

    test "sortable columns expose ARIA sort state and Heroicon direction symbols" do
      cases = [
        {meta(order_by: [:name], order_directions: [:asc]), "ascending", "hero-chevron-up-mini"},
        {meta(order_by: [:name], order_directions: [:desc]), "descending",
         "hero-chevron-down-mini"},
        {meta(order_by: [:email], order_directions: [:asc]), nil, "hero-chevron-up-down-mini"}
      ]

      for {meta, aria_sort, icon_class} <- cases do
        html =
          render_component(&sortable_table/1, %{
            meta: meta,
            path: "/admin/brokers?q=ada",
            rows: [%{id: "person-1", name: "Ada", email: "ada@example.com"}]
          })

        document = parse_fragment!(html)
        [header | _] = Floki.find(document, "thead th")

        assert Floki.attribute(header, "aria-sort") == List.wrap(aria_sort)
        assert Floki.find(header, ".#{icon_class}") != []
      end
    end

    test "leaves empty-state copy to the calling page" do
      html =
        render_component(&sortable_table/1, %{
          meta: meta(order_by: [:name], order_directions: [:asc]),
          path: "/admin/brokers",
          rows: []
        })

      assert html |> parse_fragment!() |> Floki.text() |> String.trim() == ""
    end
  end

  describe "pagination/1" do
    test "renders labeled navigation, current page, links, and ellipses" do
      html =
        render_component(&pagination/1, %{
          label: "Broker pages",
          meta:
            meta(
              current_page: 5,
              total_pages: 12,
              order_by: [:name],
              order_directions: [:desc]
            ),
          path: "/admin/brokers?q=ada"
        })

      document = parse_fragment!(html)

      assert Floki.find(document, "nav[aria-label='Broker pages']") != []

      assert document |> Floki.find("[aria-current='page']") |> List.first() |> normalized_text() ==
               "5"

      assert document |> Floki.find("a[rel='prev']") |> List.first() |> normalized_text() ==
               "Previous"

      assert document |> Floki.find("a[rel='next']") |> List.first() |> normalized_text() ==
               "Next"

      assert document |> Floki.find("span[aria-hidden='true']") |> length() == 2
    end

    test "renders previous and next disabled states as non-interactive controls" do
      first_page =
        (&pagination/1)
        |> render_component(%{
          label: "Broker pages",
          meta: meta(current_page: 1, total_pages: 2),
          path: "/admin/brokers?q=ada"
        })
        |> parse_fragment!()

      last_page =
        (&pagination/1)
        |> render_component(%{
          label: "Broker pages",
          meta: meta(current_page: 2, total_pages: 2),
          path: "/admin/brokers?q=ada"
        })
        |> parse_fragment!()

      assert first_page
             |> Floki.find("[aria-disabled='true']:not([href])")
             |> Enum.map(&normalized_text/1) == ["Previous"]

      assert Floki.find(first_page, "a[rel='prev'][href]") == []

      assert last_page
             |> Floki.find("[aria-disabled='true']:not([href])")
             |> Enum.map(&normalized_text/1) == ["Next"]

      assert Floki.find(last_page, "a[rel='next'][href]") == []
    end

    test "page URLs preserve search and current ordering" do
      html =
        render_component(&pagination/1, %{
          label: "Broker pages",
          meta:
            meta(
              current_page: 2,
              total_pages: 4,
              order_by: [:name, :id],
              order_directions: [:desc, :asc]
            ),
          path: "/admin/brokers?q=ada"
        })

      document = parse_fragment!(html)
      [next_link] = Floki.find(document, "a[rel='next']")

      assert next_link
             |> Floki.attribute("href")
             |> List.first()
             |> decoded_query()
             |> Map.take(["q", "page", "order_by", "order_directions"]) == %{
               "q" => "ada",
               "page" => "3",
               "order_by" => ["name", "id"],
               "order_directions" => ["desc", "asc"]
             }
    end
  end

  defp plain_table(assigns) do
    ~H"""
    <CoreComponents.table id="people" rows={@rows}>
      <:col :let={person} label="Name">{person.name}</:col>
      <:col :let={person} label="Email">{person.email}</:col>
    </CoreComponents.table>
    """
  end

  defp sortable_table(assigns) do
    ~H"""
    <CoreComponents.table id="people" rows={@rows} meta={@meta} path={@path}>
      <:col :let={person} label="Name" field={:name}>{person.name}</:col>
      <:col :let={person} label="Email">{person.email}</:col>
    </CoreComponents.table>
    """
  end

  defp pagination(assigns) do
    ~H"""
    <CoreComponents.pagination meta={@meta} path={@path} label={@label} />
    """
  end

  defp meta(opts) do
    current_page = Keyword.get(opts, :current_page, 1)
    total_pages = Keyword.get(opts, :total_pages, 1)
    order_by = Keyword.get(opts, :order_by, [:email])
    order_directions = Keyword.get(opts, :order_directions, [:asc])

    %Flop.Meta{
      current_offset: (current_page - 1) * 25,
      current_page: current_page,
      flop: %Flop{
        order_by: order_by,
        order_directions: order_directions,
        page: current_page,
        page_size: 25
      },
      has_next_page?: current_page < total_pages,
      has_previous_page?: current_page > 1,
      next_page: if(current_page < total_pages, do: current_page + 1),
      page_size: 25,
      previous_page: if(current_page > 1, do: current_page - 1),
      schema: Invitation,
      total_count: total_pages * 25,
      total_pages: total_pages
    }
  end

  defp parse_fragment!(html) do
    {:ok, document} = Floki.parse_fragment(html)
    document
  end

  defp normalized_text(node) do
    node
    |> Floki.text()
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp decoded_query(path) do
    path
    |> URI.parse()
    |> Map.fetch!(:query)
    |> Plug.Conn.Query.decode()
  end
end
