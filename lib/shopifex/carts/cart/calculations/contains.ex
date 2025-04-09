defmodule Shopifex.Carts.Cart.Calculations.Contains do
  @moduledoc false
  use Ash.Resource.Calculation

  @impl true
  def load(_query, _opts, _context) do
    [cart_items: [:dynamic_product_id, :product_variant]]
  end

  @impl true
  def calculate(carts, _opts, %{
        arguments: %{product_type: :static, product_id: product_variant_id}
      }) do
    Enum.map(carts, fn cart ->
      Enum.any?(cart.cart_items, &(&1.product_variant_id == product_variant_id))
    end)
  end

  @impl true
  def calculate(carts, _opts, %{
        arguments: %{product_type: _product_type, product_id: dynamic_product_id}
      }) do
    Enum.map(carts, fn cart ->
      Enum.any?(cart.cart_items, &(&1.dynamic_product_id == dynamic_product_id))
    end)
  end
end
