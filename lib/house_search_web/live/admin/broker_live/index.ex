defmodule HouseSearchWeb.Admin.BrokerLive.Index do
  use HouseSearchWeb, :live_view

  alias HouseSearch.Accounts
  alias HouseSearch.Accounts.User

  @flop_param_keys ~w(after before filters first last limit offset order_by order_directions page page_size)

  @impl true
  def mount(_params, _session, socket) do
    admin? = match?(%User{system_role: :admin, status: :active}, socket.assigns.current_user)

    {:ok,
     assign(socket,
       admin?: admin?,
       form: to_form(%{}, as: "invitation"),
       search_form: to_form(%{"q" => ""}, as: "search"),
       invitations: [],
       meta: nil,
       list_path: ~p"/admin/brokers"
     )}
  end

  @impl true
  def handle_params(params, _uri, %{assigns: %{admin?: true}} = socket) do
    {invitations, meta} = Accounts.list_brokers(params)
    q = params |> Map.get("q", "") |> normalize_q()

    {:noreply,
     assign(socket,
       invitations: invitations,
       meta: meta,
       search_form: to_form(%{"q" => q}, as: "search"),
       list_path: build_list_path(params, q, meta)
     )}
  end

  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  @impl true
  def handle_event("validate", %{"invitation" => params}, socket) do
    changeset =
      %Accounts.Invitation{}
      |> Accounts.Invitation.changeset(
        params,
        socket.assigns.current_user.id,
        DateTime.utc_now()
      )
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset, as: "invitation"))}
  end

  def handle_event("invite", %{"invitation" => params}, socket) do
    if socket.assigns.admin? do
      case Accounts.invite_broker(
             socket.assigns.current_user,
             params,
             &url(~p"/invitations/#{&1}")
           ) do
        {:ok, _invitation} ->
          {:noreply, refresh_list(socket, "Invitation ready.")}

        {:error, :pilot_limit_reached} ->
          {:noreply, put_flash(socket, :error, "Pilot participant limit reached.")}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, form: to_form(changeset, as: "invitation"))}
      end
    else
      {:noreply, put_flash(socket, :error, "Access denied.")}
    end
  end

  @impl true
  def handle_event("search", %{"search" => %{"q" => q}}, socket) do
    q = normalize_q(q)

    {:noreply, push_patch(socket, to: search_path(socket.assigns.list_path, q))}
  end

  @impl true
  def handle_event("revoke", %{"id" => id}, socket) do
    case Accounts.revoke_invitation(socket.assigns.current_user, id) do
      {:ok, _} -> {:noreply, refresh_list(socket, "Invitation revoked.")}
      {:error, reason} -> {:noreply, put_flash(socket, :error, to_string(reason))}
    end
  end

  defp refresh_list(socket, message) do
    socket
    |> put_flash(:info, message)
    |> assign(form: to_form(%{}, as: "invitation"))
    |> push_patch(to: socket.assigns.list_path)
  end

  defp build_list_path(params, q, meta) do
    params =
      params
      |> Map.drop(["q" | @flop_param_keys])
      |> put_q(q)

    ~p"/admin/brokers?#{params}"
    |> Flop.Phoenix.build_path(meta)
  end

  defp search_path(list_path, q) do
    params =
      list_path
      |> URI.parse()
      |> Map.get(:query, "")
      |> Plug.Conn.Query.decode()
      |> Map.delete("page")
      |> put_q(q)

    ~p"/admin/brokers?#{params}"
  end

  defp put_q(params, ""), do: Map.delete(params, "q")
  defp put_q(params, q), do: Map.put(params, "q", q)

  defp normalize_q(q) when is_binary(q), do: String.trim(q)
  defp normalize_q(_q), do: ""
end
