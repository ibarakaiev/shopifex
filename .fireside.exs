# Fireside configuration
[
  lib: [
    "lib/shopifex/products.ex",
    "lib/shopifex/products/**/*.{ex,exs}",
    # TODO: move into :ash_money installer
    "lib/shopifex/cldr.ex"
  ],
  overwritable: ["lib/shopifex/products/definitions.ex"],
  tests: [
    # "test/shopifex/**/*_test.{ex,exs}"
  ]
]
