defmodule Shopifex.Products.Enums.ProductType do
  @moduledoc false
  use Ash.Type.Enum,
    values: [:static] ++ Enum.map(Shopifex.Products.Definitions.dynamic_products(), & &1.handle)

  alias Shopifex.Products.Product

  def to_resource(type) do
    case type do
      :static -> Product
    end
  end

  def modules do
    Enum.map(values(), &to_resource(&1))
  end

  def all_type_resource_pairs do
    Enum.zip(values(), modules())
  end

  def dynamic_type_resource_pairs do
    dynamic_types = Enum.reject(values(), &(&1 == :static))

    Enum.zip(dynamic_types, Enum.map(dynamic_types, &to_resource(&1)))
  end
end
