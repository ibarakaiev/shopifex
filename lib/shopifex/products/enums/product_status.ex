defmodule Shopifex.Products.Enums.ProductStatus do
  @moduledoc false
  use Ash.Type.Enum, values: [:active, :archived, :draft]
end
