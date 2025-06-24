# Used by "mix format"
[
  import_deps: [:ash_postgres, :ash, :ash_admin, :ash_state_machine],
  inputs: ["{mix,.formatter,fireside}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  plugins: [Spark.Formatter]
]
