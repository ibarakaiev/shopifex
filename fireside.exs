defmodule Shopifex.Fireside do
  def app do
    %{
      lib: [
        "lib/shopifex/products.ex",
        "lib/shopifex/products/**/*.{ex,exs}"
      ],
      overwritable: ["lib/shopifex/products/definitions.ex"],
      tests: [
        "test/shopifex/**/*_test.{ex,exs}"
      ],
      test_supports: [
        "test/support/products_factory.ex"
      ]
    }
  end
end
