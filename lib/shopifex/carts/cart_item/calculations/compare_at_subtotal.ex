defmodule Shopifex.Carts.CartItem.Calculations.CompareAtSubtotal do
  @moduledoc false
  use Ash.Resource.Calculation

  alias Shopifex.Carts.CartItem

  @impl true
  def load(_query, _opts, _context) do
    []
  end

  @impl true
  def calculate(cart_items, _opts, _arguments) do
    Enum.map(cart_items, fn cart_item ->
      price_variant = cart_item.product_variant.display_price_variant

      case price_variant.compare_at_price do
        nil ->
          nil

        # subtotal may be higher than the compare-at price due to add-ons,
        # so we need to add the original difference between the base price and
        # the compare-at price to the actual subtotal
        _compare_at_price ->
          diff =
            price_variant.compare_at_price
            |> Money.sub!(price_variant.price)
            |> Money.mult!(cart_item.quantity)

          Money.add!(diff, CartItem.subtotal!(cart_item))
      end
    end)
  end
end
