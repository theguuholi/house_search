defmodule HouseSearchWeb.InvitationLive do
  use HouseSearchWeb, :live_view

  alias HouseSearch.Accounts
  alias HouseSearch.Accounts.Invitation

  def mount(%{"token" => token}, _session, socket) do
    invitation = Accounts.get_invitation_by_token(token)
    state = invitation_state(invitation, socket.assigns[:current_user])

    {:ok,
     assign(socket,
       token: token,
       invitation: invitation,
       state: state,
       form: to_form(%{}, as: "user")
     )}
  end

  def handle_event("validate", %{"user" => params}, socket) do
    form =
      %Accounts.User{}
      |> Accounts.User.password_changeset(params, hash_password: false)
      |> Map.put(:action, :validate)
      |> to_form(as: "user")

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("activate", %{"user" => params}, socket) do
    case Accounts.accept_invitation(socket.assigns.token, params, socket.assigns[:current_user]) do
      {:ok, %{user: user}} ->
        {:noreply,
         socket
         |> put_flash(:info, "Invitation accepted. You can log in now.")
         |> redirect(to: ~p"/users/log_in?_action=password_updated&email=#{user.email}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: "user"))}

      {:error, :signed_in_as_different_user} ->
        {:noreply, assign(socket, state: :different_user)}

      {:error, reason} ->
        {:noreply, assign(socket, state: reason)}
    end
  end

  defp invitation_state(nil, _current_user), do: :not_found

  defp invitation_state(%Invitation{} = invitation, current_user) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    cond do
      different_signed_in_user?(invitation, current_user) ->
        :different_user

      Invitation.usable?(invitation, now) ->
        :usable

      true ->
        Invitation.unusable_reason(invitation)
    end
  end

  defp different_signed_in_user?(_invitation, nil), do: false

  defp different_signed_in_user?(invitation, user) do
    Invitation.normalize_email(invitation.email) != Invitation.normalize_email(user.email)
  end

  defp subtitle(:usable), do: "Set your password to join the invite-only pilot."

  defp subtitle(:different_user),
    do: "Sign out and open this invitation with the matching email address."

  defp subtitle(:already_accepted), do: "This invitation has already been accepted."
  defp subtitle(:revoked), do: "This invitation is no longer available."
  defp subtitle(:expired), do: "This invitation has expired."
  defp subtitle(:not_found), do: "This invitation is invalid or unavailable."
  defp subtitle(:accepted), do: "This invitation has already been accepted."
end
