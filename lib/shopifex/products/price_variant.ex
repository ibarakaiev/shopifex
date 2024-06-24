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

    references do
      reference :product_variant, on_delete: :delete
    end
  end

  attributes do
    uuid_primary_key :id

    # actual price charged
    attribute :price, AshMoney.Types.Money, allow_nil?: false, public?: true

    # "original" price (if on sale)
    attribute :compare_at_price, AshMoney.Types.Money, public?: true

    attribute :add_ons, {:array, PriceVariant.AddOn}, public?: true

    timestamps()
  end

  relationships do
    belongs_to :product_variant, Shopifex.Products.ProductVariant, public?: true
  end

  actions do
    # it should not be possible to update PriceVariant for integrity & analytics purposes
    defaults [:read, :destroy, create: [:price, :compare_at_price, :add_ons, :product_variant_id]]

    read :by_id do
      argument :id, :uuid, allow_nil?: false

      get? true

      filter expr(id == ^arg(:id))
    end
  end

  code_interface do
    domain Shopifex.Products

    define :create, action: :create
    define :read_all, action: :read
    define :get_by_id, action: :by_id, args: [:id]
  end
end
