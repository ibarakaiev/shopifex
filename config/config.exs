import Config

config :ash, known_types: [AshMoney.Types.Money]
config :ex_cldr, default_backend: Shopifex.Cldr
config :shopifex, ecto_repos: [Shopifex.Repo]
config :shopifex, ash_domains: [Shopifex.Products, Shopifex.Carts, Shopifex.Checkouts]
config :shopifex, shopifex_dynamic_products: %{}

config :spark,
  formatter: [
    remove_parens?: true,
    "Ash.Resource": [
      section_order: [
        :resource,
        :code_interface,
        :actions,
        :policies,
        :pub_sub,
        :preparations,
        :changes,
        :validations,
        :multitenancy,
        :attributes,
        :relationships,
        :calculations,
        :aggregates,
        :identities
      ]
    ],
    "Ash.Domain": [section_order: [:resources, :policies, :authorization, :domain, :execution]]
  ]

import_config "#{config_env()}.exs"
