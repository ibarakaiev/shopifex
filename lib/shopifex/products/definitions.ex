defmodule Shopifex.Products.Definitions do
  @moduledoc """
  This module contains the definitions and configurations for dynamic products.
  """

  # format: %{
  #   handle: :"dynamic-product-handle",
  #   module: Shopifex.Products.Dynamic.DynamicProductHandle
  # }
  @dynamic_products []

  def dynamic_products, do: @dynamic_products
end
