defmodule Shopifex.Products.ProductAttributes do
  use Ash.Resource,
    domain: Shopifex.Products,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "product_attributes"

    repo Shopifex.Repo

    references do
      reference :product, on_delete: :delete
      reference :attribute, on_delete: :delete
    end
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
  end

  relationships do
    belongs_to :product, Shopifex.Products.Product,
      primary_key?: true,
      allow_nil?: false

    belongs_to :attribute, Shopifex.Products.Attribute,
      primary_key?: true,
      allow_nil?: false
  end
end
