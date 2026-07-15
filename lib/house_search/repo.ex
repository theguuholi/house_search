defmodule HouseSearch.Repo do
  use Ecto.Repo,
    otp_app: :house_search,
    adapter: Ecto.Adapters.Postgres
end
