defmodule Shopifex.Products.Product do
  @moduledoc false
  use Ash.Resource,
    domain: Shopifex.Products,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshArchival.Resource]

  alias Shopifex.Products.Product.Calculations

  require Ash.Resource.Change.Builtins

  postgres do
    repo Shopifex.Repo

    table "products"
  end

  calculations do
    # uses :selected_variant if set, otherwise picks the oldest variant
    calculate :display_product_variant,
              :struct,
              Calculations.DisplayProductVariant,
              constraints: [instance_of: Shopifex.Products.ProductVariant]

    calculate :personalizable?, :boolean, expr(type != :static)
  end

  preparations do
    # all variants and the variant that gets displayed
    prepare build(load: [:selected_product_variant, :display_product_variant])
  end

  attributes do
    uuid_primary_key :id

    attribute :title, :string, allow_nil?: false, public?: true
    attribute :description, :string, allow_nil?: false, public?: true

    attribute :image_urls, {:array, :string}, public?: true

    attribute :status, Shopifex.Products.Enums.ProductStatus,
      allow_nil?: false,
      default: :draft,
      public?: true

    # displayed in the URL
    attribute :handle, :string, allow_nil?: false, public?: true

    # i.e. :default (non-customizable) or :trivia (allows polymorphism)
    attribute :type, Shopifex.Products.Enums.ProductType, allow_nil?: false, public?: true

    timestamps()
  end

  relationships do
    has_many :product_variants, Shopifex.Products.ProductVariant

    belongs_to :selected_product_variant, Shopifex.Products.ProductVariant,
      description:
        "If set, will overwrite the default behavior of loading the oldest-created variant"
  end

  identities do
    identity :handle, [:handle]
  end

  actions do
    defaults [:read, :destroy, update: :*]

    # TODO: validate that :type is equal to :handle unless :type is :standard
    create :create do
      primary? true

      accept :*

      argument :default_product_variant, :map, allow_nil?: false

      # create the passed `default_variant` as a variant
      # (it will be selected as `display_variant`) since it will be the oldest
      change manage_relationship(:default_product_variant, :product_variants, type: :create)
    end

    update :add_product_variant do
      require_atomic? false

      argument :product_variant, :map, allow_nil?: false

      change manage_relationship(:product_variant, :product_variants,
               on_lookup: :relate,
               on_no_match: :create
             )
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

  code_interface do
    domain Shopifex.Products

    define :create, action: :create
    define :read_all, action: :read
    define :get_by_id, action: :by_id, args: [:id]
    define :get_by_handle, action: :by_handle, args: [:handle]
    define :update, action: :update
    define :add_product_variant, action: :add_product_variant
    define :destroy, action: :destroy

    define_calculation :personalizable?, args: [:_record]
  end
end
