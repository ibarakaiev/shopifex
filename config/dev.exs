import Config

config :shopifex, Shopifex.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "shopifex_dev",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
