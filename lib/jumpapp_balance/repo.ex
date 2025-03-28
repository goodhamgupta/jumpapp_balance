defmodule JumpappBalance.Repo do
  use Ecto.Repo,
    otp_app: :jumpapp_balance,
    adapter: Ecto.Adapters.SQLite3
end
