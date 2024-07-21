defmodule Shopifex.Products.Product.Calculations.DisplayProductVariant do
  @moduledoc false
  use Ash.Resource.Calculation

  alias Shopifex.Products.ProductVariant

  @impl true
  def load(_query, _opts, _context) do
    [:selected_product_variant, product_variants: [:inserted_at]]
  end

  @impl true
  def calculate(products, _opts, _context) do
    Enum.map(products, fn product ->
      # if selected_variant is set, then use it;
      # otherwise, load the oldest variant
      case product.selected_product_variant do
        nil ->
          product.product_variants
          |> Enum.min(&NaiveDateTime.before?(&1.inserted_at, &2.inserted_at))
          |> then(fn product_variant -> ProductVariant.get_by_id!(product_variant.id) end)

        selected_product_variant ->
          selected_product_variant
      end
    end)
  end
end
