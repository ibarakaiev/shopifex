defmodule Shopifex.Products do
  @moduledoc false
  use Ash.Domain, extensions: [AshAdmin.Domain]

  alias __MODULE__

  resources do
    resource Shopifex.Products.Product
    resource Shopifex.Products.ProductVariant
    resource Shopifex.Products.PriceVariant

    for %{module: dynamic_product_module} <- Products.Definitions.dynamic_products() do
      resource dynamic_product_module
    end
  end

  admin do
    show?(true)
  end
end
