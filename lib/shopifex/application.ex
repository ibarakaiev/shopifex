defmodule Shopifex.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [Shopifex.Repo]

    opts = [strategy: :one_for_one, name: Shopifex.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
