defmodule HouseSearch.Accounts.Authorization do
  import Ecto.Query, warn: false

  alias HouseSearch.Accounts.Membership
  alias HouseSearch.Accounts.User
  alias HouseSearch.Repo

  @admin_operations [:invite_broker, :suspend_user, :restore_user, :manage_brokers, :admin_read]
  @member_operations [:read, :mutate, :broker_read, :broker_mutate]

  def authorize(%User{status: :suspended}, _operation, _resource), do: {:error, :suspended}
  def authorize(%{status: :suspended}, _operation, _resource), do: {:error, :suspended}

  def authorize(%User{system_role: :admin}, operation, _resource)
      when operation in @admin_operations,
      do: :ok

  def authorize(%{system_role: :admin}, operation, _resource) when operation in @admin_operations,
    do: :ok

  def authorize(%User{} = user, operation, %{account_id: account_id})
      when operation in @member_operations,
      do: authorize_membership(user.id, account_id)

  def authorize(%{user_id: user_id, account_id: actor_account_id}, operation, %{
        account_id: account_id
      })
      when operation in @member_operations do
    with true <- actor_account_id == account_id,
         %User{} = user <- Repo.get(User, user_id),
         :ok <- authorize(user, operation, %{account_id: account_id}) do
      :ok
    else
      false -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
      nil -> {:error, :unauthorized}
    end
  end

  def authorize(%User{}, operation, _resource) when operation in @admin_operations,
    do: {:error, :unauthorized}

  def authorize(_, _, _), do: {:error, :unauthorized}

  defp authorize_membership(user_id, account_id) do
    Membership
    |> where([m], m.user_id == ^user_id and m.account_id == ^account_id)
    |> Repo.exists?()
    |> case do
      true -> :ok
      false -> {:error, :not_found}
    end
  end
end
