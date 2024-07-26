defmodule Shopifex.Products.Product.Calculations.Price do
  use Ash.Resource.Calculation

  alias Shopifex.Products.Product
  alias Shopifex.Products.ProductVariant
  alias Shopifex.Products.PriceVariant

  @impl true
  def calculate(products, _opts, %{arguments: arguments} = _context) do
    price_variant_id = arguments[:price_variant_id]

    Enum.map(products, fn product ->
      case price_variant_id do
        nil ->
          display_product_variant = Product.display_product_variant!(product)
          display_price_variant = ProductVariant.display_price_variant!(display_product_variant)

          display_price_variant.price

        price_variant_id ->
          price_variant = PriceVariant.get_by_id!(price_variant_id)

          if price_variant.product_id != product.id do
            raise "Price variant from a different product was provided"
          end

          price_variant.price
      end
    end)
  end
end
