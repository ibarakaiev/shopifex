defmodule Shopifex.Carts.CartItem.Calculations.Subtotal do
  @moduledoc false
  use Ash.Resource.Calculation

  alias Shopifex.Products.ProductVariant

  @impl true
  def load(_query, _opts, _context) do
    [:quantity, :product_variant_id, :price_variant_id, :product_type]
  end

  @impl true
  def calculate(cart_items, _opts, _context) do
    Enum.map(cart_items, fn cart_item ->
      case cart_item.product_type do
        :static ->
          product_variant = ProductVariant.get_by_id!(cart_item.product_variant_id)

          display_price_variant =
            ProductVariant.display_price_variant!(
              product_variant,
              cart_item.price_variant_id
            )

          Money.mult!(display_price_variant.price, cart_item.quantity)

        type ->
          resource = Shopifex.Products.Enums.ProductType.to_resource(type)

          dynamic_product = resource.get_by_id!(cart_item.dynamic_product_id)

          dynamic_product
          |> resource.subtotal!(cart_item.price_variant_id)
          |> Money.mult!(cart_item.quantity)
      end
    end)
  end
end
