# Fireside configuration
[
  includes: [
    "lib/shopifex/products.ex",
    "lib/shopifex/products/**/*.{ex.exs}",
    "test/shopifex/**/*.{ex,exs}",
    "test/support/products_factory.ex"
  ],
  overwritable: ["lib/shopifex/products/definitions.ex"]
]
