defmodule Shopifex.Products.ProductVariant do
  @moduledoc false
  use Ash.Resource,
    domain: Shopifex.Products,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshArchival.Resource]

  alias __MODULE__.Calculations

  postgres do
    repo Shopifex.Repo

    table "product_variants"

    references do
      reference :product, on_delete: :delete
    end
  end

  code_interface do
    domain Shopifex.Products

    define :create, action: :create
    define :read_all, action: :read
    define :get_by_id, action: :by_id, args: [:id]

    define :get_by_alias_and_product_id,
      action: :by_alias_and_product_id,
      args: [:alias, :product_id]
  end

  actions do
    defaults [:read, :destroy, update: [:alias]]

    create :create do
      primary? true

      argument :default_price_variant, :map, allow_nil?: false

      accept [:alias, :product_id]

      change manage_relationship(:default_price_variant, :price_variants, type: :create)
    end

    read :by_id do
      argument :id, :uuid, allow_nil?: false

      get? true

      filter expr(id == ^arg(:id))
    end

    read :by_alias_and_product_id do
      argument :alias, :string, allow_nil?: false
      argument :product_id, :uuid, allow_nil?: false

      get? true

      filter expr(product_id == ^arg(:product_id) and alias == ^arg(:alias))
    end
  end

  preparations do
    prepare build(load: [:default_price_variant])
  end

  attributes do
    uuid_primary_key :id

    attribute :alias, :string, public?: true

    timestamps()
  end

  relationships do
    has_many :price_variants, Shopifex.Products.PriceVariant, public?: true

    belongs_to :product, Shopifex.Products.Product, public?: true
  end

  calculations do
    calculate :default_price_variant, :struct, Calculations.DefaultPriceVariant,
      constraints: [instance_of: Shopifex.Products.PriceVariant]
  end

  identities do
    identity :unique_alias, [:product_id, :alias]
  end
end
