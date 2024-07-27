defmodule Shopifex.Carts.CartItem.Calculations.DisplayDescription do
  @moduledoc false
  use Ash.Resource.Calculation

  alias Shopifex.Products.Enums.ProductType
  alias Shopifex.Products.ProductVariant

  @impl true
  def load(_query, _opts, _context) do
    [:product_type, :dynamic_product_id, :product_variant]
  end

  @impl true
  def calculate(cart_items, _opts, _params) do
    Enum.map(cart_items, fn cart_item ->
      case cart_item.product_type do
        :static ->
          product_variant = ProductVariant.get_by_id!(cart_item.product_variant_id)
          product_variant.description

        product_type ->
          resource = ProductType.to_resource(product_type)

          resource.get_by_id!(cart_item.dynamic_product_id).description
      end
    end)
  end
end
