defmodule Shopifex.Products.ProductUnion do
  @moduledoc """
  Defines a new type for the union of all possible products. Used for polymorphism in carts
  and orders, i.e. a cart may contain standard (fixed) products linking to
  just their definitions or personalized products linking to their instances.
  """
  use Ash.Type.NewType,
    subtype_of: :union,
    constraints: [
      types:
        Enum.map(Shopifex.Products.Enums.ProductType.all_type_resource_pairs(), fn {type, module} ->
          {type, [type: :struct, constraints: [instance_of: module]]}
        end)
    ]
end
