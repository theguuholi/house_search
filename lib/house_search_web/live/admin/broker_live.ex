defmodule HouseSearchWeb.Admin.BrokerLive do
  use HouseSearchWeb, :live_view

  alias HouseSearch.Accounts
  alias HouseSearch.Accounts.User

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-5xl space-y-8">
      <.header>
        Broker access
        <:subtitle>Invite, suspend, and restore pilot brokers.</:subtitle>
      </.header>

      <div :if={!@admin?} class="rounded border border-zinc-200 p-4 text-sm">
        Access denied.
      </div>

      <div :if={@admin?} class="space-y-6">
        <.simple_form for={@form} id="invite_form" phx-submit="invite" phx-change="validate">
          <.input field={@form[:name]} label="Broker name" required />
          <.input field={@form[:email]} type="email" label="Email" required />
          <:actions>
            <.button>Send invitation</.button>
          </:actions>
        </.simple_form>

        <.simple_form for={@search_form} id="search_form" phx-change="search">
          <.input field={@search_form[:q]} label="Search" />
        </.simple_form>

        <.table id="invitations" rows={@invitations}>
          <:col :let={invitation} label="Broker">{invitation.name}</:col>
          <:col :let={invitation} label="Email">{invitation.email}</:col>
          <:col :let={invitation} label="Status">{invitation.status}</:col>
          <:action :let={invitation}>
            <.button phx-click="revoke" phx-value-id={invitation.id}>Revoke</.button>
          </:action>
        </.table>
      </div>
    </div>
    """
  end

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
        Map.merge(params, %{
          "inviter_id" => socket.assigns.current_user.id,
          "expires_at" => DateTime.utc_now()
        })
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
    {:noreply,
     assign(socket,
       search_form: to_form(%{"q" => q}, as: "search"),
       invitations: Accounts.list_brokers(search: q)
     )}
  end

  def handle_event("revoke", %{"id" => id}, socket) do
    invitation = HouseSearch.Repo.get!(Accounts.Invitation, id)

    case Accounts.revoke_invitation(socket.assigns.current_user, invitation) do
      {:ok, _} -> {:noreply, reload(socket, "Invitation revoked.")}
      {:error, reason} -> {:noreply, put_flash(socket, :error, to_string(reason))}
    end
  end

  defp reload(socket, message) do
    socket
    |> put_flash(:info, message)
    |> assign(form: to_form(%{}, as: "invitation"), invitations: Accounts.list_brokers())
  end
end
