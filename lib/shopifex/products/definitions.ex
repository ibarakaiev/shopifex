defmodule Shopifex.Products.Definitions do
  def dynamic_products do
    Application.fetch_env!(:shopifex, :dynamic_products)
  end

  def dynamic_product_handles do
    Map.keys(dynamic_products())
  end

  def dynamic_product_modules do
    dynamic_products()
    |> Map.values()
    |> Enum.flat_map(fn
      %{primary: primary, nested: nested} -> [primary, nested]
      %{primary: primary} -> [primary]
      module when is_atom(module) -> module
    end)
  end
end
