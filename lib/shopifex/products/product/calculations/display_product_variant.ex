defmodule Shopifex.Products.Product.Calculations.DisplayProductVariant do
  @moduledoc false
  use Ash.Resource.Calculation

  alias Shopifex.Products.ProductVariant

  @impl true
  def load(_query, _opts, _context) do
    [:selected_product_variant_id]
  end

  @impl true
  def calculate(products, _opts, %{arguments: arguments} = _context) do
    product_variant_id = arguments[:product_variant_id]

    Enum.map(products, fn product ->
      case product_variant_id do
        nil ->
          # if selected_product_variant is set, then use it;
          # otherwise, load the oldest variant
          case product.selected_product_variant_id do
            nil ->
              product = Ash.load!(product, [:product_variants])

              product.product_variants
              |> Enum.min(&NaiveDateTime.before?(&1.inserted_at, &2.inserted_at))

            selected_product_variant_id ->
              ProductVariant.get_by_id!(selected_product_variant_id)
          end

        product_variant_id ->
          ProductVariant.get_by_id!(product_variant_id)
      end
    end)
  end
end
