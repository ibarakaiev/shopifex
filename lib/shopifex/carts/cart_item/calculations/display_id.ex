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

          # cart_item may have the same products but different product variants or price variants,
          # so to prevent collision (and anonymize price variant ids) we add a random string
          display_product.handle <> "_" <> random_string(8)

        _product_type ->
          {:ok, display_product} = Ash.load(cart_item.display_product, [:hash])

          display_product.hash
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
