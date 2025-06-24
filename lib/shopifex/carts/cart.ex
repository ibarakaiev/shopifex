defmodule Shopifex.Carts.Cart do
  @moduledoc false
  use Ash.Resource,
    domain: Shopifex.Carts,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshStateMachine],
    notifiers: [Ash.Notifier.PubSub]

  alias __MODULE__
  alias __MODULE__.Actions
  alias __MODULE__.Calculations

  alias Shopifex.Products.ProductVariant

  postgres do
    table "carts"
    repo Shopifex.Repo
  end

  state_machine do
    initial_states [:active]
    default_initial_state :active

    transitions do
      transition :complete_checkout, from: :active, to: :order_created
    end
  end

  code_interface do
    domain Shopifex.Carts

    define :create, action: :create
    define :read_all, action: :read
    define :destroy, action: :destroy

    define :add_to_cart, action: :add_to_cart, args: [:cart_item]
    define :complete_checkout, action: :complete_checkout

    define :add_new_checkout_session, action: :add_new_checkout_session
    define :expire_all_checkout_sessions, action: :expire_all_checkout_sessions

    define :get_by_id, args: [:id], action: :by_id

    define_calculation :active_checkout_session, args: [:_record]
    define_calculation :contains?, args: [:_record, :product_type, :product_id]
    define_calculation :empty?, args: [:_record]
    define_calculation :subtotal, args: [:_record]
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]

    update :add_to_cart do
      require_atomic? false

      argument :cart_item, :map, allow_nil?: false

      change fn changeset, _ ->
        {:ok, cart_item} = Ash.Changeset.fetch_argument(changeset, :cart_item)

        product_variant = cart_item[:product_variant]

        cart_item =
          if Map.has_key?(cart_item, :price_variant) do
            cart_item
          else
            Map.put(
              cart_item,
              :price_variant,
              ProductVariant.display_price_variant!(product_variant)
            )
          end

        Ash.Changeset.force_set_argument(changeset, :cart_item, cart_item)
      end

      change manage_relationship(:cart_item, :cart_items,
               on_no_match: {:create, :create_or_increment_quantity},
               on_match: :on_no_match,
               on_lookup: :relate
             )

      change after_action(fn changeset, cart, _context ->
               Cart.expire_all_checkout_sessions(cart)
             end)
    end

    update :add_new_checkout_session do
      require_atomic? false

      manual Actions.AddNewCheckoutSession
    end

    update :expire_all_checkout_sessions do
      require_atomic? false

      manual Actions.ExpireAllCheckoutSessions
    end

    update :complete_checkout do
      change transition_state(:order_created)
    end

    read :by_id do
      argument :id, :uuid, allow_nil?: false

      get? true

      filter expr(id == ^arg(:id))
    end
  end

  pub_sub do
    module ShopifexWeb.Endpoint

    prefix "cart"

    publish_all :update, ["updated", :cart_id]
  end

  preparations do
    prepare build(load: [:cart_items])
  end

  attributes do
    uuid_primary_key :id
  end

  relationships do
    has_many :cart_items, Shopifex.Carts.CartItem
    has_many :checkout_sessions, Shopifex.Checkouts.CheckoutSession
  end

  calculations do
    calculate :active_checkout_session, :struct, Calculations.ActiveCheckoutSession,
      constraints: [instance_of: Shopifex.Checkouts.CheckoutSession]

    calculate :contains?, :boolean, Calculations.Contains do
      argument :product_type, :atom, allow_nil?: false
      argument :product_id, :uuid, allow_nil?: false
    end

    calculate :empty?, AshMoney.Types.Money, Calculations.Empty
    calculate :subtotal, AshMoney.Types.Money, Calculations.Subtotal
  end
end
