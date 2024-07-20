defmodule Shopifex.Carts.CartItem.Calculations.DisplayId do
  @moduledoc false
  use Ash.Resource.Calculation

  @impl true
  def load(_query, _opts, _context) do
    [:product_type, :display_product]
  end

  @impl true
  def calculate(cart_items, _opts, _params) do
    Enum.map(cart_items, fn cart_item ->
      case cart_item.product_type do
        :static ->
          {:ok, display_product} = Ash.load(cart_item.display_product, [:handle])

          display_product.handle

        _product_type ->
          {:ok, display_product} = Ash.load(cart_item.display_product, [:hash])

          display_product.hash
      end
    end)
  end
end
