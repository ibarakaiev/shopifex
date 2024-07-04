defmodule Shopifex.ProductsTest do
  use Shopifex.DataCase, async: true

  use Shopifex.ProductsFactory

  alias Shopifex.Products.PriceVariant
  alias Shopifex.Products.Product
  alias Shopifex.Products.ProductVariant

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
    {:ok, product} = insert(Product)
    {:ok, product_variant} = insert(ProductVariant, attrs: %{product_id: product.id})
    {:ok, _price_variant} = insert(PriceVariant, attrs: %{product_variant_id: product_variant.id})

    # reload to load calculated fields
    {:ok, product} = Product.get_by_id(product.id)

    %{
      product: product,
      product_variant: product_variant
    }
  end

  test "Product.create/2 successfully creates a product with an associated variant" do
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

    {:ok, product} = Ash.load(product, [:display_product_variant])

    assert product.title == @product_attrs[:title]

    assert product.display_product_variant.default_price_variant.price ==
             @default_variant_attrs[:price]
  end

  test "Product.get_by_id/3 successfully returns the product with loaded variants and display_product_variant",
       %{
         product: product,
         product_variant: %{
           id: product_variant_id
         }
       } do
    {:ok, loaded_product} = Product.get_by_id(product.id)

    assert loaded_product.id == product.id
    assert [%{id: ^product_variant_id}] = loaded_product.product_variants
    assert %{id: ^product_variant_id} = loaded_product.display_product_variant
  end

  test "Product.add_product_variant/2 successfully adds a new variant", %{product: product} do
    {:ok, product} =
      Product.add_product_variant(product, %{
        product_variant: %{default_price_variant: %{price: "49.99", compare_at_price: "59.99"}}
      })

    assert length(product.product_variants) == 2
  end
end
