defmodule Shopifex.Products.ProductTypeTest do
  use ExUnit.Case

  alias Shopifex.Products.Enums.ProductType

  test "ProductType works with defined modules" do
    for {handle, module} <- Shopifex.Products.Definitions.dynamic_products() do
      assert ProductType.to_resource(handle) == module
      assert function_exported?(module, :__info__, 1)
    end
  end
end
