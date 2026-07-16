defmodule HouseSearch.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HouseSearch.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> HouseSearch.Accounts.register_user()

    user
  end

  def admin_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> HouseSearch.Accounts.register_admin()

    user
  end

  def broker_fixture(attrs \\ %{}) do
    attrs = Map.new(attrs)
    admin = Map.get_lazy(attrs, :admin, &admin_fixture/0)
    email = Map.get(attrs, :email, unique_user_email())
    name = Map.get(attrs, :name, "Pilot Broker")

    {:ok, invitation} =
      HouseSearch.Accounts.invite_broker(admin, %{email: email, name: name}, fn token ->
        "https://example.com/invitations/#{token}"
      end)

    {:ok, %{user: user, account: account}} =
      HouseSearch.Accounts.accept_invitation(
        invitation.token,
        %{password: valid_user_password(), password_confirmation: valid_user_password()}
      )

    %{user: user, account: account}
  end

  def invitation_fixture(attrs \\ %{}) do
    attrs = Map.new(attrs)
    admin = Map.get_lazy(attrs, :admin, &admin_fixture/0)
    email = Map.get(attrs, :email, unique_user_email())
    name = Map.get(attrs, :name, "Pilot Broker")

    {:ok, pending} =
      HouseSearch.Accounts.invite_broker(admin, %{email: email, name: name}, fn token ->
        "https://example.com/invitations/#{token}"
      end)

    invitation =
      pending.token
      |> HouseSearch.Accounts.Invitation.hash_token()
      |> then(&HouseSearch.Repo.get_by!(HouseSearch.Accounts.Invitation, token_hash: &1))

    %{invitation: invitation, token: pending.token, admin: admin}
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
