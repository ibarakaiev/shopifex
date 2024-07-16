defmodule Shopifex.Repo do
  use AshPostgres.Repo, otp_app: :shopifex

  def installed_extensions do
    # Add extensions here, and the migration generator will install them.
    ["ash-functions", AshMoney.AshPostgresExtension]
  end
end
