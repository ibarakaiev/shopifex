defmodule Shopifex.Products.Product.Calculations.Title do
  use Ash.Resource.Calculation

  alias Shopifex.Products.Product

  @impl true
  def calculate(products, _opts, %{arguments: arguments} = _context) do
    product_variant_id = arguments[:product_variant_id]

    Enum.map(products, fn product ->
      Product.display_product_variant!(product, product_variant_id).title
    end)
  end
end
