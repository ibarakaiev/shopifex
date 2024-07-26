defmodule Shopifex.Products.ProductVariant.Calculations.CompareAtPrice do
  @moduledoc false
  use Ash.Resource.Calculation

  @impl true
  def calculate(product_variants, _opts, %{arguments: arguments} = _context) do
    currency = Map.get(arguments, :currency, :USD)

    Enum.map(product_variants, fn product_variant ->
      product_variant = Ash.load!(product_variant, :price_variants)

      most_expensive_price_variant =
        product_variant.price_variants
        |> Enum.filter(&(&1.price.currency == currency))
        |> Enum.max(&(Money.compare!(&1.price, &2.price) == :gt))

      most_expensive_price_variant.price
    end)
  end
end
