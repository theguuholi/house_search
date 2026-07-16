defmodule HouseSearchWeb.Admin.BrokerLive.Index do
  use HouseSearchWeb, :live_view

  alias HouseSearch.Accounts
  alias HouseSearch.Accounts.User

  def mount(params, _session, socket) do
    admin? = match?(%User{system_role: :admin, status: :active}, socket.assigns.current_user)
    q = Map.get(params, "q", "")
    page = Map.get(params, "page", "1")

    {:ok,
     assign(socket,
       admin?: admin?,
       form: to_form(%{}, as: "invitation"),
       search_form: to_form(%{"q" => q}, as: "search"),
       invitations: if(admin?, do: Accounts.list_brokers(search: q, page: page), else: [])
     )}
  end

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
          {:noreply, reload(socket, "Invitation ready.")}

        {:error, :pilot_limit_reached} ->
          {:noreply, put_flash(socket, :error, "Pilot participant limit reached.")}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, form: to_form(changeset, as: "invitation"))}
      end
    else
      {:noreply, put_flash(socket, :error, "Access denied.")}
    end
  end

  def handle_event("search", %{"search" => %{"q" => q}}, socket) do
    invitations = if socket.assigns.admin?, do: Accounts.list_brokers(search: q), else: []

    {:noreply,
     assign(socket, search_form: to_form(%{"q" => q}, as: "search"), invitations: invitations)}
  end

  def handle_event("revoke", %{"id" => id}, socket) do
    case Accounts.revoke_invitation(socket.assigns.current_user, id) do
      {:ok, _} -> {:noreply, reload(socket, "Invitation revoked.")}
      {:error, reason} -> {:noreply, put_flash(socket, :error, to_string(reason))}
    end
  end

  defp reload(socket, message) do
    invitations = if socket.assigns.admin?, do: Accounts.list_brokers(), else: []

    socket
    |> put_flash(:info, message)
    |> assign(form: to_form(%{}, as: "invitation"), invitations: invitations)
  end
end
