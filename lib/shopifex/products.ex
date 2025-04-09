defmodule Shopifex.Products do
  @moduledoc false
  use Ash.Domain, extensions: [AshAdmin.Domain]

  alias __MODULE__

  admin do
    show? true
  end

  resources do
    resource Shopifex.Products.Attribute
    resource Shopifex.Products.AttributeOption
    resource Shopifex.Products.PriceVariant
    resource Shopifex.Products.Product
    resource Shopifex.Products.ProductAttributes
    resource Shopifex.Products.ProductVariant
    resource Shopifex.Products.ProductVariantPriceVariant

    # dynamic products can be configured in `config.exs` with either of the
    # following two formats:
    #
    # %{
    #   :"first-product" => FirstProductModule,
    #   :"second-product" => %{
    #     primary: SecondProductModule,
    #     nested: [SecondProductModule.Feature]
    #   }
    # }
    #
    for dynamic_product_module <- Products.Definitions.dynamic_product_modules() do
      resource dynamic_product_module
    end
  end
end
