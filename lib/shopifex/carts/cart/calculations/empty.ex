defmodule Shopifex.Carts.Cart.Calculations.Empty do
  @moduledoc false
  use Ash.Resource.Calculation

  @impl true
  def load(_query, _opts, _context) do
    [:cart_items]
  end

  @impl true
  def calculate(carts, _opts, _arguments) do
    Enum.map(carts, fn cart ->
      Enum.empty?(cart.cart_items)
    end)
  end
end
