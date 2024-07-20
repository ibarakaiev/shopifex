defmodule Shopifex.Checkouts.CheckoutSession do
  @moduledoc false
  use Ash.Resource,
    domain: Shopifex.Checkouts,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshStateMachine],
    notifiers: [Ash.Notifier.PubSub]

  postgres do
    table "checkout_sessions"
    repo Shopifex.Repo

    references do
      reference :cart, on_delete: :delete
    end
  end

  state_machine do
    initial_states([:open])
    default_initial_state(:open)

    transitions do
      transition(:complete_checkout, from: :open, to: :complete)
      transition(:expire, from: :open, to: :expired)
    end
  end

  code_interface do
    domain Shopifex.Checkouts

    define :create, action: :create

    define :read_all, action: :read
    define :get_by_id, args: [:id], action: :by_id

    define :complete_checkout, action: :complete_checkout
    define :expire, action: :expire
  end

  actions do
    defaults [:read, create: [:cart_id]]

    read :by_id do
      argument :id, :uuid, allow_nil?: false

      get? true

      filter expr(id == ^arg(:id))
    end

    update :complete_checkout do
      change transition_state(:complete)
    end

    update :expire do
      change transition_state(:expired)
    end
  end

  pub_sub do
    module ShopifexWeb.Endpoint

    prefix "checkout_session"

    publish_all :create, ["created", :cart_id]
    publish_all :update, ["updated", :cart_id]
    publish_all :destroy, ["destroyed", :cart_id]
  end

  preparations do
    prepare build(load: [:cart])
  end

  attributes do
    uuid_primary_key :id

    timestamps()
  end

  relationships do
    belongs_to :cart, Shopifex.Carts.Cart, public?: true

    # a CheckoutSession can be implicitly associated with additional resources
    # such as with a Stripe's checkout session, an order, a customer, etc, via
    # a `belongs_to` association on their end
  end
end
