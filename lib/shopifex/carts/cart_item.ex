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
      # WARN: if the associated *dynamic* product is deleted, the associated cart item will NOT
      # be cascade deleted since it is not explicitly associated with this row (it's
      # polymorphically associated via the combination of :product_type and :dynamic_product_id
      # if :product_type is not :static
      reference :cart, on_delete: :delete
      reference :product_variant, on_delete: :delete
      reference :price_variant, on_delete: :delete
    end
  end

  code_interface do
    domain Shopifex.Carts

    define :update_quantity, action: :update_quantity
    define :read_all, action: :read
    define :destroy, action: :destroy
    define :get_by_id, action: :by_id, args: [:id]
    define_calculation :display_title, args: [:_record]
    define_calculation :display_description, args: [:_record]
    define_calculation :display_image, args: [:_record]
    define_calculation :subtotal, args: [:_record]
    define_calculation :compare_at_subtotal, args: [:_record]
  end

  actions do
    # the update action is required by Cart:
    # actions -> update -> add_to_cart -> change -> manage_relationship -> cart_item -> cart_items
    defaults [:read]

    create :create_or_increment_quantity do
      accept [:product_type, :dynamic_product_id]

      primary? true

      argument :product_variant, :map, allow_nil?: false
      argument :price_variant, :map, allow_nil?: false

      upsert? true

      upsert_identity :unique_cart_item

      change atomic_update(:quantity, expr(quantity + 1))

      change manage_relationship(:product_variant, type: :append)
      change manage_relationship(:price_variant, type: :append)
    end

    update :update do
      accept []

      primary? true

      require_atomic? false
    end

    update :update_quantity do
      require_atomic? false

      argument :quantity, :integer, allow_nil?: false

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
    prepare build(load: [:display_id, :product_variant])
  end

  changes do
    change after_action(fn _changeset, cart_item, _context ->
             cart_item.cart_id |> Cart.get_by_id!() |> Cart.expire_all_checkout_sessions!()

             {:ok, cart_item}
           end)
  end

  validations do
    validate compare(:quantity, greater_than_or_equal_to: 1)
  end

  attributes do
    uuid_primary_key :id

    attribute :quantity, :integer, allow_nil?: false, default: 1, public?: true

    # If :product_type == :static, the :product is loaded via the associated
    # :product_variant (and :dynamic_product_id is nil). Otherwise, the
    # :product is loaded depending on its type.
    attribute :product_type, Shopifex.Products.Enums.ProductType,
      allow_nil?: false,
      default: :static,
      public?: true

    attribute :dynamic_product_id, :uuid, allow_nil?: true, public?: true

    timestamps()
  end

  relationships do
    belongs_to :cart, Shopifex.Carts.Cart, primary_key?: true, allow_nil?: false, public?: true

    belongs_to :product_variant, Shopifex.Products.ProductVariant,
      domain: Shopifex.Products,
      allow_nil?: false,
      public?: true

    belongs_to :price_variant, Shopifex.Products.PriceVariant,
      domain: Shopifex.Products,
      allow_nil?: false,
      public?: true
  end

  calculations do
    calculate :display_title, :string, Calculations.DisplayTitle
    calculate :display_description, :string, Calculations.DisplayDescription
    calculate :display_image, :string, Calculations.DisplayImage
    calculate :display_id, :string, Calculations.DisplayId
    calculate :subtotal, AshMoney.Types.Money, Calculations.Subtotal
    calculate :compare_at_subtotal, AshMoney.Types.Money, Calculations.CompareAtSubtotal
  end

  identities do
    # note: price_variant_id is not part of the index as only one given product variant is allowed
    # in the cart. Otherwise the cart will end up with the same product but different prices.
    identity :unique_cart_item,
             [:cart_id, :product_variant_id, :product_type, :dynamic_product_id],
             nils_distinct?: false
  end
end
