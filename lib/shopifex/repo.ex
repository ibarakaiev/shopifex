defmodule Shopifex.Repo do
  use AshPostgres.Repo, otp_app: :shopifex

  def installed_extensions do
    [AshMoney.AshPostgresExtension, "ash-functions"]
  end
end
