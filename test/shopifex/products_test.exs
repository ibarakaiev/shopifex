defmodule Shopifex.ProductsTest do
  use Shopifex.DataCase, async: true

  alias Shopifex.Products.Enums.ProductType
  alias Shopifex.Products.Product

  @product_attrs %{
    title: "Test",
    description: "Description",
    handle: "test",
    type: :static
  }

  @default_variant_attrs %{
    price: Money.new(:USD, "39.99"),
    compare_at_price: Money.new(:USD, "49.99")
  }

  setup do
    {:ok, product} =
      Product.create(%{
        title: @product_attrs[:title],
        description: @product_attrs[:description],
        handle: @product_attrs[:handle],
        type: @product_attrs[:type],
        default_product_variant: %{
          default_price_variant: %{
            price: @default_variant_attrs[:price],
            compare_at_price: @default_variant_attrs[:compare_at_price]
          }
        }
      })

    %{
      product: product
    }
  end

  test "Product.get_by_id/3 successfully returns the product with loaded display_product_variant",
       %{
         product: product
       } do
    {:ok, loaded_product} = Product.get_by_id(product.id)

    assert loaded_product.id == product.id
    assert product.title == @product_attrs[:title]

    assert loaded_product.display_product_variant.default_price_variant.price ==
             @default_variant_attrs[:price]
  end

  test "Product.add_product_variant/2 successfully adds a new variant", %{product: product} do
    {:ok, product} =
      product
      |> Product.add_product_variant(%{
        product_variant: %{default_price_variant: %{price: "49.99", compare_at_price: "59.99"}}
      })
      |> Ash.load(:product_variants)

    assert length(product.product_variants) == 2
  end

  test ":display_product_variant contains the oldest added product_variant if no selected_product_variant is set", %{product: product} do
    {:ok, product} =
      product
      |> Product.add_product_variant!(%{
        product_variant: %{default_price_variant: %{price: "49.99"}}
      })
      |> Ash.load([:display_product_variant, :selected_product_variant])

    assert is_nil(product.selected_product_variant)

    assert Money.equal?(
             product.display_product_variant.default_price_variant.price,
             Money.new(:USD, "39.99")
           )
  end

  test ":display_product_variant contains :selected_product_variant if it it set", %{product: product} do
    {:ok, product} =
      product
      |> Product.add_product_variant(%{
        product_variant: %{default_price_variant: %{price: "49.99"}}
      })
      |> Ash.load(:product_variants)

    newly_added_product_variant = Enum.find(product.product_variants, &Money.equal?(&1.default_price_variant.price, Money.new(:USD, "49.99")))

    {:ok, product} =
      product
      |> Product.update(%{selected_product_variant_id: newly_added_product_variant.id})
      |> Ash.load(:display_product_variant)

    assert Money.equal?(
             product.display_product_variant.default_price_variant.price,
             newly_added_product_variant.default_price_variant.price
           )
  end

  for {_type, resource} <- ProductType.dynamic_type_resource_pairs() do
    @tag resource: resource
    test "implements subtotal!/1", %{resource: resource} do
      assert function_exported?(resource, :subtotal, 1)
    end
  end
end
