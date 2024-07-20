defmodule Shopifex.Carts.CartItem do
  @moduledoc false
  use Ash.Resource,
    domain: Shopifex.Carts,
    data_layer: AshPostgres.DataLayer,
    notifiers: [Ash.Notifier.PubSub]

  alias __MODULE__.Calculations
  alias Shopifex.Carts.Cart

  postgres do
    table "cart_items"
    repo Shopifex.Repo

    references do
      # WARN: if a product is deleted, the associated cart item will NOT be cascade deleted
      # since it is not explicitly associated with this row (it's polymorphically associated
      # via [:product_type, :dynamic_product_id, product_variant: [:id]])
      reference :cart, on_delete: :delete
    end
  end

  code_interface do
    domain Shopifex.Carts

    define :update_quantity, action: :update_quantity
    define :read_all, action: :read
    define :destroy, action: :destroy
    define :get_by_id, action: :by_id, args: [:id]
    define_calculation :subtotal, args: [:_record]
    define_calculation :compare_at_subtotal, args: [:_record]
  end

  actions do
    # the update action is required by Cart:
    # actions -> update -> add_to_cart -> change -> manage_relationship -> cart_item -> cart_items
    defaults [:read, update: []]

    create :create_or_increment_quantity do
      accept [:product_type, :dynamic_product_id]

      primary? true

      argument :product_variant, :map, allow_nil?: false

      upsert? true

      upsert_identity :unique_cart_item

      change atomic_update(:quantity, expr(quantity + 1))

      change manage_relationship(:product_variant, type: :append)
    end

    update :update_quantity do
      require_atomic? false

      argument :quantity, :integer, allow_nil?: false

      change before_action(fn changeset, _context ->
               cart_item = changeset.data

               cart_item.cart_id |> Cart.get_by_id!() |> Cart.expire_all_checkout_sessions!()

               changeset
             end)

      change atomic_update(:quantity, expr(^arg(:quantity)))
    end

    read :by_id do
      argument :id, :uuid, allow_nil?: false

      get? true

      filter expr(id == ^arg(:id))
    end

    destroy :destroy do
      require_atomic? false

      primary? true

      change before_action(fn changeset, _context ->
               cart_item = changeset.data

               cart_item.cart_id |> Cart.get_by_id!() |> Cart.expire_all_checkout_sessions!()

               changeset
             end)
    end
  end

  pub_sub do
    module ShopifexWeb.Endpoint

    prefix "cart_item"

    publish_all :create, ["created", :cart_id]
    publish_all :update, ["updated", :cart_id]
    publish_all :destroy, ["destroyed", :cart_id]
  end

  preparations do
    prepare build(sort: [inserted_at: :asc])
    prepare build(load: [:display_product, :display_id, product_variant: [:product]])
  end

  validations do
    validate compare(:quantity, greater_than_or_equal_to: 1)
  end

  attributes do
    uuid_primary_key :id

    attribute :quantity, :integer, allow_nil?: false, default: 1

    # If :product_type == :static, the :product is loaded via the associated
    # :product_variant (and :dynamic_product_id is nil). Otherwise, the
    # :product is loaded depending on its type.
    attribute :product_type, Shopifex.Products.Enums.ProductType,
      allow_nil?: false,
      default: :static

    attribute :dynamic_product_id, :uuid, allow_nil?: true

    timestamps()
  end

  relationships do
    belongs_to :cart, Shopifex.Carts.Cart, primary_key?: true, allow_nil?: false
    belongs_to :product_variant, Shopifex.Products.ProductVariant, domain: Shopifex.Products
  end

  calculations do
    calculate :display_product, Shopifex.Products.ProductUnion, Calculations.Product
    calculate :display_id, :string, Calculations.DisplayId
    calculate :subtotal, AshMoney.Types.Money, Calculations.Subtotal
    calculate :compare_at_subtotal, AshMoney.Types.Money, Calculations.CompareAtSubtotal
  end

  identities do
    identity :unique_cart_item,
             [:cart_id, :product_variant_id, :product_type, :dynamic_product_id],
             nils_distinct?: false
  end
end
