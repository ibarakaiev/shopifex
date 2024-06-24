defmodule Shopifex.Products.ProductVariant.Calculations.DefaultPriceVariant do
  @moduledoc false
  use Ash.Resource.Calculation

  alias Shopifex.Products.PriceVariant

  @impl true
  def load(_query, _opts, _context) do
    [price_variants: [:inserted_at]]
  end

  @impl true
  def calculate(product_variants, _opts, _context) do
    Enum.map(product_variants, fn product_variant ->
      if length(product_variant.price_variants) > 0 do
        product_variant.price_variants
        |> Enum.min_by(&Map.get(&1, :inserted_at))
        # loads the remaining fields
        |> then(fn price_variant -> PriceVariant.get_by_id!(price_variant.id) end)
      end
    end)
  end
end
