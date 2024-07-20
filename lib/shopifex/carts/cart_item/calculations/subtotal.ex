defmodule Shopifex.Carts.CartItem.Calculations.Subtotal do
  @moduledoc false
  use Ash.Resource.Calculation

  @impl true
  def load(_query, _opts, _context) do
    [:quantity, product_variant: [default_price_variant: [:price]]]
  end

  @impl true
  def calculate(cart_items, _opts, _arguments) do
    Enum.map(cart_items, fn cart_item ->
      case cart_item.product_type do
        :static ->
          Money.mult!(cart_item.product_variant.default_price_variant.price, cart_item.quantity)

        type ->
          resource = Shopifex.Products.Enums.ProductType.to_resource(type)

          dynamic_product = resource.get_by_id!(cart_item.dynamic_product_id)

          dynamic_product
          |> resource.subtotal!()
          |> Money.mult!(cart_item.quantity)
      end
    end)
  end
end
