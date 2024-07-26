defmodule Shopifex.Products.PriceVariant do
  @moduledoc false
  use Ash.Resource,
    domain: Shopifex.Products,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshArchival.Resource]

  alias __MODULE__

  postgres do
    repo Shopifex.Repo

    table "price_variants"
  end

  code_interface do
    domain Shopifex.Products

    define :create, action: :create
    define :read_all, action: :read
    define :get_by_id, action: :by_id, args: [:id]
  end

  actions do
    # it should not be possible to update or destroy PriceVariant for integrity & analytics purposes
    defaults [:read]

    create :create do
      primary? true

      upsert? true

      upsert_identity :unique_product_price

      accept :*
    end

    read :by_id do
      argument :id, :uuid, allow_nil?: false

      get? true

      filter expr(id == ^arg(:id))
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :price, AshMoney.Types.Money, allow_nil?: false, public?: true

    attribute :add_ons, {:array, PriceVariant.AddOn}, public?: true

    timestamps()
  end

  relationships do
    many_to_many :product_variants, Shopifex.Products.ProductVariant do
      through Shopifex.Products.ProductVariantPriceVariant

      source_attribute_on_join_resource :price_variant_id
      destination_attribute_on_join_resource :product_variant_id
    end

    belongs_to :product, Shopifex.Products.Product, public?: true
  end

  identities do
    identity :unique_product_price, [:product_id, :price]
  end
end
