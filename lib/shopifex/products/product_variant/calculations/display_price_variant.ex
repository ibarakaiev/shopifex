defmodule Shopifex.Products.ProductVariant.Calculations.DisplayPriceVariant do
  @moduledoc false
  use Ash.Resource.Calculation

  alias Shopifex.Products.PriceVariant

  @impl true
  def load(_query, _opts, _context) do
    [:selected_price_variant_id]
  end

  @impl true
  def calculate(product_variants, _opts, %{arguments: arguments} = _context) do
    price_variant_id = arguments[:price_variant_id]

    Enum.map(product_variants, fn product_variant ->
      case price_variant_id do
        nil ->
          # if selected_price_variant is set, then use it;
          # otherwise, load the oldest variant
          case product_variant.selected_price_variant_id do
            nil ->
              product_variant = Ash.load!(product_variant, :price_variants)

              product_variant.price_variants
              |> Enum.min(&NaiveDateTime.before?(&1.inserted_at, &2.inserted_at))
              # loads the remaining fields
              |> then(fn price_variant -> PriceVariant.get_by_id!(price_variant.id) end)

            selected_price_variant_id ->
              PriceVariant.get_by_id!(selected_price_variant_id)
          end

        price_variant_id ->
          PriceVariant.get_by_id!(price_variant_id)
      end
    end)
  end
end
