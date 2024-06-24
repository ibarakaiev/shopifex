import Config

config :shopifex,
  ash_domains: [Shopifex.Products]

config :shopifex,
  ecto_repos: [Shopifex.Repo]

config :ex_cldr, default_backend: Shopifex.Cldr

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
