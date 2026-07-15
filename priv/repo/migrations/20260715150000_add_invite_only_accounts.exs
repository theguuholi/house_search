defmodule HouseSearch.Repo.Migrations.AddInviteOnlyAccounts do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :system_role, :string, null: false, default: "member"
      add :status, :string, null: false, default: "active"
      add :suspended_at, :utc_datetime_usec
    end

    create constraint(:users, :users_system_role_check,
             check: "system_role in ('admin', 'member')"
           )

    create constraint(:users, :users_status_check, check: "status in ('active', 'suspended')")

    create table(:accounts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :status, :string, null: false, default: "active"
      add :timezone, :string, null: false, default: "America/Sao_Paulo"
      add :pilot_started_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create constraint(:accounts, :accounts_status_check,
             check: "status in ('active', 'suspended')"
           )

    create table(:memberships, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :role, :string, null: false, default: "broker"

      timestamps(type: :utc_datetime_usec)
    end

    create constraint(:memberships, :memberships_role_check, check: "role in ('broker', 'owner')")
    create unique_index(:memberships, [:account_id, :user_id])
    create index(:memberships, [:user_id])

    create table(:pilot_settings, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :participant_limit, :integer, null: false, default: 5
      add :lock_version, :integer, null: false, default: 1

      timestamps(type: :utc_datetime_usec)
    end

    create constraint(:pilot_settings, :pilot_settings_participant_limit_check,
             check: "participant_limit >= 0"
           )

    create table(:invitations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :token_hash, :binary, null: false
      add :email, :citext, null: false
      add :name, :string, null: false
      add :inviter_id, references(:users, type: :binary_id, on_delete: :nilify_all), null: false
      add :status, :string, null: false, default: "pending"
      add :expires_at, :utc_datetime_usec, null: false
      add :accepted_at, :utc_datetime_usec
      add :accepted_user_id, references(:users, type: :binary_id, on_delete: :nilify_all)
      add :accepted_account_id, references(:accounts, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime_usec)
    end

    create constraint(:invitations, :invitations_status_check,
             check: "status in ('pending', 'accepted', 'revoked')"
           )

    create unique_index(:invitations, [:token_hash])

    create unique_index(:invitations, [:email],
             where: "status = 'pending'",
             name: :invitations_pending_email_index
           )

    create index(:invitations, [:status, :expires_at])
    create index(:invitations, [:accepted_user_id])
    create index(:invitations, [:accepted_account_id])
  end
end
