defmodule Shopifex.Products.ProductVariant do
  @moduledoc false
  use Ash.Resource,
    domain: Shopifex.Products,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshArchival.Resource]

  alias __MODULE__.Calculations
  alias __MODULE__.Changes

  postgres do
    repo Shopifex.Repo

    table "product_variants"

    references do
      reference :product, on_delete: :delete

      reference :selected_price_variant, on_delete: :nilify
    end
  end

  code_interface do
    domain Shopifex.Products

    define :create, action: :create
    define :read_all, action: :read
    define :get_by_id, action: :by_id, args: [:id]

    define :add_price_variant, action: :add_price_variant, args: [:price_variant]

    define :select_display_price_variant,
      action: :select_display_price_variant,
      args: [:selected_price_variant_id]

    define :get_by_alias_and_product_id,
      action: :by_alias_and_product_id,
      args: [:alias, :product_id]

    define_calculation :display_price_variant, args: [:_record, {:optional, :price_variant_id}]
    define_calculation :compare_at_price, args: [:_record]
  end

  actions do
    defaults [:read, :destroy, update: [:alias]]

    create :create do
      primary? true

      argument :price_variants, {:array, :map}, allow_nil?: false

      accept [:alias, :title, :description, :image_urls, :product_id]

      change Changes.AddProductIdToPriceVariants

      change manage_relationship(:price_variants,
               on_lookup: :relate,
               on_no_match: :create
             )
    end

    update :add_price_variant do
      require_atomic? false

      argument :price_variants, {:array, :map}, allow_nil?: false

      change Changes.AddProductIdToPriceVariants

      change manage_relationship(:price_variants,
               on_lookup: :relate,
               on_no_match: :create
             )
    end

    update :select_display_price_variant do
      argument :selected_price_variant_id, :uuid, allow_nil?: false

      change atomic_update(:selected_price_variant_id, expr(^arg(:selected_price_variant_id)))
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

  attributes do
    uuid_primary_key :id

    attribute :alias, :string, public?: true

    attribute :title, :string, allow_nil?: false, public?: true
    attribute :description, :string, allow_nil?: false, public?: true

    attribute :image_urls, {:array, :string}, public?: true

    attribute :selected_price_variant_id, :uuid, public?: true

    timestamps()
  end

  relationships do
    many_to_many :price_variants, Shopifex.Products.PriceVariant do
      through Shopifex.Products.ProductVariantPriceVariant

      source_attribute_on_join_resource :product_variant_id
      destination_attribute_on_join_resource :price_variant_id
    end

    belongs_to :product, Shopifex.Products.Product, public?: true, allow_nil?: false

    belongs_to :selected_price_variant, Shopifex.Products.PriceVariant, public?: true
  end

  calculations do
    calculate :display_price_variant, :struct, Calculations.DisplayPriceVariant do
      constraints instance_of: Shopifex.Products.PriceVariant
      argument :price_variant_id, :uuid, allow_nil?: true
    end

    calculate :compare_at_price, AshMoney.Types.Money, Calculations.CompareAtPrice
  end

  identities do
    identity :unique_alias, [:product_id, :alias]
  end
end
