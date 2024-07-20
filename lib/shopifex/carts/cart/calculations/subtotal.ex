defmodule Shopifex.Carts.Cart.Calculations.Subtotal do
  @moduledoc false
  use Ash.Resource.Calculation

  alias Shopifex.Carts.CartItem

  @impl true
  def load(_query, _opts, _context) do
    [:cart_items]
  end

  @impl true
  def calculate(carts, _opts, _arguments) do
    Enum.map(carts, fn cart ->
      Enum.reduce(cart.cart_items, Money.new(:USD, 0), fn cart_item, subtotal ->
        cart_item
        |> CartItem.subtotal!()
        |> Money.add!(subtotal)
      end)
    end)
  end
end
