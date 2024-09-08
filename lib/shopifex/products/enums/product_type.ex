defmodule Shopifex.Products.Enums.ProductType do
  @moduledoc false
  use Ash.Type.Enum,
    values: [:static] ++ Shopifex.Products.Definitions.dynamic_product_handles()

  def to_resource(type) do
    case type do
      :static ->
        Shopifex.Products.Product

      _ ->
        case Shopifex.Products.Definitions.dynamic_products()[type] do
          %{primary: module} -> module
          module -> module
        end
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
