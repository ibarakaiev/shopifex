defmodule Shopifex.ProductsTest do
  use Shopifex.DataCase, async: true

  alias Shopifex.Products.Enums.ProductType
  alias Shopifex.Products.Product
  alias Shopifex.Products.ProductVariant
  alias Shopifex.Products.PriceVariant

  @product_attrs %{
    handle: "test",
    type: :static
  }

  @product_variant_attrs %{
    title: "Test 1",
    description: "Description 1"
  }

  @price_variant_attrs %{
    price: Money.new(:USD, "39.99")
  }

  @compare_at_price_variant_attrs %{
    price: Money.new(:USD, "49.99")
  }

  setup do
    product =
      Product.create!(%{
        handle: @product_attrs[:handle],
        type: @product_attrs[:type],
        product_variants: [
          %{
            title: @product_variant_attrs[:title],
            description: @product_variant_attrs[:description],
            price_variants: [
              %{
                price: @price_variant_attrs[:price]
              },
              %{
                price: @compare_at_price_variant_attrs[:price]
              }
            ]
          }
        ]
      })

    %{
      product: Product.get_by_id!(product.id)
    }
  end

  describe "Product" do
    test "is created successfully", %{product: product} do
      assert product.status == :draft
      assert product.handle == @product_attrs[:handle]
      assert product.type == @product_attrs[:type]

      assert Product.title!(product) == @product_variant_attrs[:title]
      assert Product.description!(product) == @product_variant_attrs[:description]

      assert Money.equal?(Product.price!(product), @price_variant_attrs[:price])

      display_product_variant = Product.display_product_variant!(product)
      display_price_variant = ProductVariant.display_price_variant!(display_product_variant)

      assert display_price_variant.product_id == product.id
    end

    test "add_product_variants/2 adds news product variants with new prices", %{
      product: product
    } do
      product =
        product
        |> Product.add_product_variants!([
          %{
            title: "Test 2",
            description: "Description 2",
            price_variants: [%{price: Money.new(:USD, "59.99")}]
          }
        ])
        |> Ash.load!(:product_variants)

      assert length(product.product_variants) == 2

      all_price_variants = PriceVariant.read_all!()

      assert length(all_price_variants) == 3
    end

    test "add_product_variants/2 adds news product variants and reuses existing prices",
         %{
           product: product
         } do
      product =
        product
        |> Product.add_product_variants!([
          %{
            title: "Test 2",
            description: "Description 2",
            price_variants: [%{price: Money.new(:USD, "39.99")}]
          }
        ])
        |> Ash.load!(:product_variants)

      assert length(product.product_variants) == 2

      all_price_variants = PriceVariant.read_all!()

      assert length(all_price_variants) == 2
    end

    test "display_product_variant/1,2", %{
      product: product
    } do
      product =
        product
        |> Product.add_product_variants!([
          %{
            title: "Test 2",
            description: "Description 2",
            price_variants: [%{price: Money.new(:USD, "59.99")}]
          }
        ])
        |> Ash.load!(:product_variants)

      newly_added_product_variant_id =
        Enum.find(product.product_variants, &(&1.title == "Test 2")).id

      assert is_nil(product.selected_product_variant_id)

      original_display_product_variant_id = Product.display_product_variant!(product).id

      # currently set as it is the oldest oldest
      assert original_display_product_variant_id != newly_added_product_variant_id

      product = Product.select_display_product_variant!(product, newly_added_product_variant_id)

      assert Product.display_product_variant!(product).id == newly_added_product_variant_id

      assert Product.display_product_variant!(product, original_display_product_variant_id).id ==
               original_display_product_variant_id

      assert Product.title!(product, original_display_product_variant_id) ==
               @product_variant_attrs[:title]

      refute Product.title!(product) == @product_variant_attrs[:title]

      assert Product.description!(product, original_display_product_variant_id) ==
               @product_variant_attrs[:description]

      refute Product.description!(product) == @product_variant_attrs[:description]
    end
  end

  describe "ProductVariant" do
    test "compare_at_price/2 returns the highest price in a product", %{
      product: product
    } do
      display_product_variant = Product.display_product_variant!(product)

      compare_at_price = ProductVariant.compare_at_price!(display_product_variant)

      assert Money.equal?(compare_at_price, @compare_at_price_variant_attrs[:price])
    end

    test "display_price_variant/1,2",
         %{product: product} do
      product_variant = Product.display_product_variant!(product) |> Ash.load!(:price_variants)

      lowest_price_variant =
        Enum.find(
          product_variant.price_variants,
          &Money.equal?(&1.price, Money.new(:USD, "39.99"))
        )

      highest_price_variant =
        Enum.find(
          product_variant.price_variants,
          &Money.equal?(&1.price, Money.new(:USD, "49.99"))
        )

      assert is_nil(product_variant.selected_price_variant_id)

      # currently set because it was first in the list and is thus the oldest
      assert ProductVariant.display_price_variant!(product_variant).id == lowest_price_variant.id

      product_variant =
        ProductVariant.select_display_price_variant!(product_variant, highest_price_variant.id)

      assert ProductVariant.display_price_variant!(product_variant).id == highest_price_variant.id

      assert ProductVariant.display_price_variant!(product_variant, lowest_price_variant.id).id ==
               lowest_price_variant.id

      refute Product.price!(product) == @price_variant_attrs[:price]
      assert Product.price!(product, lowest_price_variant.id) == @price_variant_attrs[:price]
    end
  end

  for {_type, resource} <- ProductType.dynamic_type_resource_pairs() do
    @tag resource: resource
    test "implements subtotal!/1,2", %{resource: resource} do
      # without an optional price_variant_id
      assert function_exported?(resource, :subtotal, 1)
      # with a price_variant_id
      assert function_exported?(resource, :subtotal, 2)
    end

    @tag resource: resource
    test "implements title!/1", %{resource: resource} do
      assert function_exported?(resource, :title, 1)
    end
  end
end
