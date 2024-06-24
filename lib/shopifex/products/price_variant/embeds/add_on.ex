defmodule Shopifex.Products.PriceVariant.AddOn do
  @moduledoc false
  use Ash.Resource, data_layer: :embedded

  attributes do
    attribute :name, :string, allow_nil?: false, public?: true
    attribute :price, AshMoney.Types.Money, allow_nil?: false, public?: true
  end
end
