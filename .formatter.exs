# Used by "mix format"
[
  import_deps: [:ash_postgres, :ash],
  inputs: ["{mix,.formatter,fireside}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  plugins: [Spark.Formatter]
]
