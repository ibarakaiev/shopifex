defmodule Shopifex.Carts.CartItem.Calculations.CompareAtSubtotal do
  @moduledoc false
  use Ash.Resource.Calculation

  alias Shopifex.Carts.CartItem
  alias Shopifex.Products.ProductVariant
  alias Shopifex.Products.PriceVariant

  @impl true
  def load(_query, _opts, _context) do
    []
  end

  # TODO: test this calculation
  @impl true
  def calculate(cart_items, _opts, _arguments) do
    Enum.map(cart_items, fn cart_item ->
      product_variant = ProductVariant.get_by_id!(cart_item.product_variant_id)

      price = PriceVariant.get_by_id!(cart_item.price_variant_id).price
      compare_at_price = ProductVariant.compare_at_price!(product_variant)

      unless Money.equal?(price, compare_at_price) do
        diff =
          compare_at_price
          |> Money.sub!(price)
          |> Money.mult!(cart_item.quantity)

        Money.add!(diff, CartItem.subtotal!(cart_item))
      end
    end)
  end
end
