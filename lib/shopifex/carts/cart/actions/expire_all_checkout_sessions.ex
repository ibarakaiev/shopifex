defmodule Shopifex.Carts.Cart.Actions.ExpireAllCheckoutSessions do
  @moduledoc false
  use Ash.Resource.ManualUpdate

  alias Shopifex.Carts.Cart
  alias Shopifex.Checkouts.CheckoutSession

  def update(%{data: cart}, _opts, _context) do
    {:ok, %Cart{checkout_sessions: checkout_sessions}} = Ash.load(cart, [:checkout_sessions])

    for checkout_session <- checkout_sessions, checkout_session.state == :open do
      CheckoutSession.expire!(checkout_session)
    end

    {:ok, Cart.get_by_id!(cart.id)}
  end
end
