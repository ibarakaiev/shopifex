defmodule Shopifex.Checkouts do
  @moduledoc false
  use Ash.Domain, extensions: [AshAdmin.Domain]

  admin do
    show?(true)
  end

  resources do
    resource Shopifex.Checkouts.CheckoutSession
  end
end
