defmodule Shopifex.Carts.CartItem.Calculations.DisplayId do
  @moduledoc false
  use Ash.Resource.Calculation

  alias Shopifex.Products.ProductVariant
  alias Shopifex.Products.Enums.ProductType

  @impl true
  def load(_query, _opts, _context) do
    [:product_type, :product_variant_id, :dynamic_product_id]
  end

  @impl true
  def calculate(cart_items, _opts, _params) do
    Enum.map(cart_items, fn cart_item ->
      case cart_item.product_type do
        :static ->
          product_variant =
            ProductVariant.get_by_id!(cart_item.product_variant_id, load: [:product])

          product_variant.product.handle <> "_" <> random_string(8)

        product_type ->
          resource = ProductType.to_resource(product_type)

          resource.get_by_id!(cart_item.dynamic_product_id).hash
      end
    end)
  end

  defp random_string(length) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.encode16()
    |> binary_part(0, length)
    |> String.downcase()
  end
end
