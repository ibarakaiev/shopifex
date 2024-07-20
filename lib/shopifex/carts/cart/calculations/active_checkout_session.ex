defmodule Shopifex.Carts.Cart.Calculations.ActiveCheckoutSession do
  @moduledoc false
  use Ash.Resource.Calculation

  @impl true
  def load(_query, _opts, _context) do
    [checkout_sessions: [:state]]
  end

  @impl true
  def calculate(carts, _opts, _params) do
    Enum.map(carts, fn cart ->
      case Enum.find(cart.checkout_sessions, &(&1.state == :open)) do
        nil ->
          nil

        checkout_session ->
          checkout_session
      end
    end)
  end
end
