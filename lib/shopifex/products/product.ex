defmodule Shopifex.Products.Product do
  @moduledoc false
  use Ash.Resource,
    domain: Shopifex.Products,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshArchival.Resource]

  alias __MODULE__.Calculations
  alias __MODULE__.Changes

  postgres do
    repo Shopifex.Repo

    table "products"

    references do
      reference :selected_product_variant, on_delete: :nilify
    end
  end

  code_interface do
    domain Shopifex.Products

    define :create, action: :create
    define :read_all, action: :read
    define :get_by_id, action: :by_id, args: [:id]
    define :get_by_handle, action: :by_handle, args: [:handle]
    define :update_status, action: :update_status, args: [:status]

    define :add_product_variants, action: :add_product_variants, args: [:product_variants]

    define :select_display_product_variant,
      action: :select_display_product_variant,
      args: [:selected_product_variant_id]

    define :destroy, action: :destroy

    define_calculation :display_product_variant,
      args: [:_record, {:optional, :product_variant_id}]

    define_calculation :dynamic?, args: [:_record]

    define_calculation :title, args: [:_record, {:optional, :product_variant_id}]
    define_calculation :description, args: [:_record, {:optional, :product_variant_id}]
    define_calculation :price, args: [:_record, {:optional, :price_variant_id}]
  end

  actions do
    defaults [:read, :destroy, update: :*]

    create :create do
      primary? true

      accept :*

      argument :product_variants, {:array, :map}, allow_nil?: false

      change Changes.AddProductIdToProductVariants

      change manage_relationship(:product_variants, type: :create)
    end

    update :add_product_variants do
      require_atomic? false

      argument :product_variants, {:array, :map}, allow_nil?: false

      change Changes.AddProductIdToProductVariants

      change manage_relationship(:product_variants, type: :create)
    end

    update :select_display_product_variant do
      argument :selected_product_variant_id, :uuid, allow_nil?: false

      change atomic_update(:selected_product_variant_id, expr(^arg(:selected_product_variant_id)))
    end

    update :update_status do
      argument :status, Shopifex.Products.Enums.ProductStatus, allow_nil?: false

      change atomic_update(:status, arg(:status))
    end

    read :by_id do
      argument :id, :uuid, allow_nil?: false

      get? true

      filter expr(id == ^arg(:id))
    end

    read :by_handle do
      argument :handle, :string, allow_nil?: false

      get? true

      filter expr(handle == ^arg(:handle))
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :status, Shopifex.Products.Enums.ProductStatus,
      allow_nil?: false,
      default: :draft,
      public?: true

    # displayed in the URL
    attribute :handle, :string, allow_nil?: false, public?: true

    attribute :type, Shopifex.Products.Enums.ProductType, allow_nil?: false, public?: true

    timestamps()
  end

  relationships do
    has_many :product_variants, Shopifex.Products.ProductVariant

    belongs_to :selected_product_variant, Shopifex.Products.ProductVariant, public?: true
  end

  calculations do
    calculate :display_product_variant,
              :struct,
              Calculations.DisplayProductVariant do
      constraints instance_of: Shopifex.Products.ProductVariant
      argument :product_variant_id, :uuid, allow_nil?: true
    end

    calculate :dynamic?, :boolean, expr(type != :static)

    calculate :title, :string, Calculations.Title do
      argument :product_variant_id, :uuid, allow_nil?: true
    end

    calculate :description, :string, Calculations.Description do
      argument :product_variant_id, :uuid, allow_nil?: true
    end

    calculate :price, AshMoney.Types.Money, Calculations.Price do
      argument :price_variant_id, :uuid, allow_nil?: true
    end

  end

  identities do
    # only one unarchived product with a given handle
    identity :handle, [:handle, :archived_at], nils_distinct?: false
  end
end
