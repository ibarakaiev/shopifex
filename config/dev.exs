import Config

# Configure your database
config :shopifex, Shopifex.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "shopifex_dev",
  port: 5432,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
