defmodule Shopifex.Products.ProductVariantPriceVariant do
  use Ash.Resource,
    domain: Shopifex.Products,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "product_variant_price_variants"

    repo Shopifex.Repo
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
  end

  relationships do
    belongs_to :product_variant, Shopifex.Products.ProductVariant,
      primary_key?: true,
      allow_nil?: false

    belongs_to :price_variant, Shopifex.Products.PriceVariant,
      primary_key?: true,
      allow_nil?: false
  end
end
