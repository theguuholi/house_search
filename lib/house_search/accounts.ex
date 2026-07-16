defmodule HouseSearch.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false

  alias HouseSearch.Accounts.Account
  alias HouseSearch.Accounts.Authorization
  alias HouseSearch.Accounts.Invitation
  alias HouseSearch.Accounts.Membership
  alias HouseSearch.Accounts.PilotSettings
  alias HouseSearch.Accounts.User
  alias HouseSearch.Accounts.UserNotifier
  alias HouseSearch.Accounts.UserToken
  alias HouseSearch.Repo

  @pilot_settings_id "00000000-0000-0000-0000-000000000001"

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)

    if User.valid_password?(user, password) && user.status == :active do
      user
    end
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def register_admin(attrs) do
    attrs
    |> Map.new()
    |> Map.put(:system_role, :admin)
    |> then(fn attrs ->
      %User{}
      |> User.registration_changeset(attrs)
      |> Ecto.Changeset.put_change(:system_role, :admin)
      |> User.confirm_changeset()
      |> Repo.insert()
    end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_user_email(user, "valid password", %{email: ...})
      {:ok, %User{}}

      iex> apply_user_email(user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- user |> user_email_multi(email, context) |> Repo.transaction() do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset =
      user
      |> User.email_changeset(%{email: email})
      |> User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm_email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    token
    |> UserToken.by_token_and_context_query("session")
    |> Repo.delete_all()

    :ok
  end

  def revoke_user_sessions(%User{} = user) do
    user
    |> UserToken.by_user_and_contexts_query(["session"])
    |> Repo.delete_all()

    HouseSearchWeb.Endpoint.broadcast("users:#{user.id}", "disconnect", %{})
    :ok
  end

  def list_brokers(opts \\ []) do
    page = max(parse_int(Keyword.get(opts, :page, 1)), 1)
    per_page = min(max(parse_int(Keyword.get(opts, :per_page, 25)), 1), 100)
    search = Keyword.get(opts, :search, "")
    offset = (page - 1) * per_page

    query =
      from i in Invitation,
        order_by: [desc: i.inserted_at, asc: i.email],
        limit: ^per_page,
        offset: ^offset

    query =
      if search && search != "" do
        term = "%#{search}%"
        where(query, [i], ilike(i.email, ^term) or ilike(i.name, ^term))
      else
        query
      end

    Repo.all(query)
  end

  def get_or_create_pilot_settings do
    Repo.get(PilotSettings, @pilot_settings_id) ||
      %PilotSettings{}
      |> PilotSettings.changeset(%{id: @pilot_settings_id})
      |> Ecto.Changeset.put_change(:id, @pilot_settings_id)
      |> Repo.insert(on_conflict: :nothing, conflict_target: :id)

    Repo.get!(PilotSettings, @pilot_settings_id)
  end

  def update_pilot_settings(attrs) do
    get_or_create_pilot_settings()
    |> PilotSettings.changeset(attrs)
    |> Repo.update()
  end

  def invite_broker(%User{} = admin, attrs, invitation_url_fun)
      when is_function(invitation_url_fun, 1) do
    with :ok <- Authorization.authorize(admin, :invite_broker, :admin),
         :ok <- ensure_pilot_capacity() do
      email = Invitation.normalize_email(attrs["email"] || attrs[:email])

      case Repo.get_by(Invitation, email: email, status: :pending) do
        %Invitation{} = invitation -> {:ok, invitation}
        nil -> insert_invitation(admin, attrs, email, invitation_url_fun)
      end
    end
  end

  def accept_invitation(token, attrs, current_user \\ nil) do
    now = DateTime.utc_now()

    with %Invitation{} = invitation <- get_invitation_by_token(token),
         :ok <- ensure_matching_identity(invitation, current_user),
         true <- Invitation.usable?(invitation, now) do
      fn -> accept_invitation_transaction(invitation, attrs, now) end
      |> Repo.transaction()
      |> case do
        {:ok, result} -> {:ok, result}
        {:error, reason} -> {:error, reason}
      end
    else
      false ->
        invitation = get_invitation_by_token(token)
        {:error, Invitation.unusable_reason(invitation)}

      nil ->
        {:error, :not_found}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_invitation_by_token(token) when is_binary(token) do
    Repo.get_by(Invitation, token_hash: Invitation.hash_token(token))
  end

  def revoke_invitation(%User{} = admin, %Invitation{} = invitation) do
    with :ok <- Authorization.authorize(admin, :manage_brokers, :admin) do
      invitation |> Invitation.revoke_changeset() |> Repo.update()
    end
  end

  def revoke_invitation(%User{} = admin, invitation_id) when is_binary(invitation_id) do
    with :ok <- Authorization.authorize(admin, :manage_brokers, :admin),
         %Invitation{} = invitation <- Repo.get(Invitation, invitation_id) do
      invitation
      |> Invitation.revoke_changeset()
      |> Repo.update()
    else
      nil -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  def suspend_user(%User{} = admin, %User{} = user) do
    with :ok <- Authorization.authorize(admin, :suspend_user, :admin) do
      now = DateTime.utc_now()

      user
      |> User.role_changeset(%{status: :suspended, suspended_at: now})
      |> Repo.update()
      |> case do
        {:ok, user} ->
          revoke_user_sessions(user)
          {:ok, user}

        error ->
          error
      end
    end
  end

  def restore_user(%User{} = admin, %User{} = user) do
    with :ok <- Authorization.authorize(admin, :restore_user, :admin) do
      user
      |> User.role_changeset(%{status: :active, suspended_at: nil})
      |> Repo.update()
    end
  end

  def actor_for_user(%User{} = user) do
    membership =
      Membership
      |> where([m], m.user_id == ^user.id)
      |> order_by([m], asc: m.inserted_at)
      |> Repo.one()

    if membership do
      %{user_id: user.id, account_id: membership.account_id}
    end
  end

  def authorize(actor_or_user, operation, resource),
    do: Authorization.authorize(actor_or_user, operation, resource)

  defp ensure_pilot_capacity do
    settings = get_or_create_pilot_settings()

    active_users =
      from(u in User, where: u.status == :active and u.system_role == :member)
      |> Repo.aggregate(:count)

    pending_invitations =
      from(i in Invitation, where: i.status == :pending)
      |> Repo.aggregate(:count)

    if active_users + pending_invitations < settings.participant_limit do
      :ok
    else
      {:error, :pilot_limit_reached}
    end
  end

  defp invitation_expiry do
    DateTime.utc_now()
    |> DateTime.add(7, :day)
  end

  defp insert_invitation(admin, attrs, email, invitation_url_fun) do
    token = 32 |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)

    attrs =
      attrs
      |> stringify_keys()
      |> Map.merge(%{"inviter_id" => admin.id, "expires_at" => invitation_expiry()})

    %Invitation{}
    |> Invitation.changeset(attrs)
    |> Invitation.token_changeset(token)
    |> Repo.insert()
    |> handle_invitation_insert(email, token, invitation_url_fun)
  end

  defp handle_invitation_insert({:ok, invitation}, _email, token, invitation_url_fun) do
    UserNotifier.deliver_invitation_instructions(invitation, invitation_url_fun.(token))
    {:ok, invitation}
  end

  defp handle_invitation_insert({:error, changeset}, email, _token, _invitation_url_fun) do
    case Repo.get_by(Invitation, email: email, status: :pending) do
      %Invitation{} = invitation -> {:ok, invitation}
      nil -> {:error, changeset}
    end
  end

  defp accept_invitation_transaction(invitation, attrs, now) do
    invitation = Repo.get!(Invitation, invitation.id, lock: "FOR UPDATE")

    if Invitation.usable?(invitation, now) do
      accept_usable_invitation!(invitation, attrs, now)
    else
      reason = Invitation.unusable_reason(invitation)
      Repo.rollback(reason)
    end
  end

  defp accept_usable_invitation!(invitation, attrs, now) do
    user = get_or_insert_invited_user!(invitation, attrs, now)
    account = insert_account!(invitation, now)
    membership = insert_membership!(account, user)

    invitation =
      invitation
      |> Invitation.accept_changeset(user.id, account.id, now)
      |> Repo.update!()

    %{user: user, account: account, membership: membership, invitation: invitation}
  end

  defp ensure_matching_identity(_invitation, nil), do: :ok

  defp ensure_matching_identity(invitation, %User{} = user) do
    if Invitation.normalize_email(user.email) == Invitation.normalize_email(invitation.email) do
      :ok
    else
      {:error, :signed_in_as_different_user}
    end
  end

  defp get_or_insert_invited_user!(invitation, attrs, now) do
    case Repo.get_by(User, email: invitation.email) do
      %User{} = user ->
        user
        |> User.password_changeset(attrs)
        |> Ecto.Changeset.put_change(:confirmed_at, DateTime.truncate(now, :second))
        |> Repo.update!()

      nil ->
        attrs = stringify_keys(attrs)

        %User{}
        |> User.registration_changeset(Map.put(attrs, "email", invitation.email))
        |> Ecto.Changeset.put_change(:confirmed_at, DateTime.truncate(now, :second))
        |> Repo.insert!()
    end
  end

  defp insert_account!(invitation, now) do
    %Account{}
    |> Account.changeset(%{name: invitation.name, pilot_started_at: now})
    |> Repo.insert!()
  end

  defp insert_membership!(account, user) do
    %Membership{}
    |> Membership.changeset(%{account_id: account.id, user_id: user.id, role: :owner})
    |> Repo.insert!(
      on_conflict: :nothing,
      conflict_target: [:account_id, :user_id]
    )
  end

  defp parse_int(value) when is_integer(value), do: value
  defp parse_int(value) when is_binary(value), do: String.to_integer(value)
  defp parse_int(_), do: 1

  defp stringify_keys(attrs) do
    Map.new(attrs, fn {key, value} -> {to_string(key), value} end)
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given user.

  ## Examples

      iex> deliver_user_confirmation_instructions(user, &url(~p"/users/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_user_confirmation_instructions(confirmed_user, &url(~p"/users/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a user by the given token.

  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- user |> confirm_user_multi() |> Repo.transaction() do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given user.

  ## Examples

      iex> deliver_user_reset_password_instructions(user, &url(~p"/users/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the user by reset password token.

  ## Examples

      iex> get_user_by_reset_password_token("validtoken")
      %User{}

      iex> get_user_by_reset_password_token("invalidtoken")
      nil

  """
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}

      iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end
end
