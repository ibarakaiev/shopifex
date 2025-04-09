defmodule Shopifex.Carts do
  @moduledoc false
  use Ash.Domain, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource Shopifex.Carts.Cart
    resource Shopifex.Carts.CartItem
  end
end
