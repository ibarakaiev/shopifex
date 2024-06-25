# Fireside configuration
[
  lib: [
    "lib/shopifex/products.ex",
    "lib/shopifex/products/**/*.{ex,exs}"
  ],
  overwritable: ["lib/shopifex/products/definitions.ex"],
  tests: [
    "test/shopifex/**/*_test.{ex,exs}"
  ]
]
