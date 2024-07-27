defmodule Shopifex.CartsTest do
  use Shopifex.DataCase, async: true

  alias Shopifex.Carts.Cart
  alias Shopifex.Carts.CartItem
  alias Shopifex.Products.Enums.ProductType
  alias Shopifex.Products.Product
  alias Shopifex.Products.ProductVariant

  setup do
    %{cart: Cart.create!()}
  end

  test "Cart.create/1 creates an empty cart" do
    cart = Ash.load!(Cart.create!(), [:cart_items, :checkout_sessions])

    assert cart.cart_items == []
    assert cart.checkout_sessions == []
  end

  test "Cart.empty?/1 returns true for an empty cart", %{cart: cart} do
    assert Cart.empty?(Cart.get_by_id!(cart.id))
  end

  test "Cart.add_new_checkout_session/1 creates a new checkout session", %{cart: cart} do
    {:ok, %{checkout_sessions: [checkout_session]}} =
      Ash.load(Cart.add_new_checkout_session(cart), :checkout_sessions)

    assert checkout_session.cart_id == cart.id
  end

  test "Cart.add_new_checkout_session/1 expires previous checkout sessions", %{cart: cart} do
    %{checkout_sessions: checkout_sessions} =
      cart
      |> Cart.add_new_checkout_session!()
      |> Cart.add_new_checkout_session!()
      |> Ash.load!(:checkout_sessions)

    [first_checkout_session, second_checkout_session] =
      Enum.sort(
        checkout_sessions,
        &NaiveDateTime.before?(&1.inserted_at, &2.inserted_at)
      )

    assert first_checkout_session.state == :expired
    assert second_checkout_session.state == :open
  end

  test "active_checkout_session/1 contains the correct active checkout session", %{
    cart: cart
  } do
    %{checkout_sessions: checkout_sessions} =
      cart
      |> Cart.add_new_checkout_session!()
      |> Cart.add_new_checkout_session!()
      |> Ash.load!(:checkout_sessions)

    [_first_checkout_session, second_checkout_session] =
      Enum.sort(
        checkout_sessions,
        &NaiveDateTime.before?(&1.inserted_at, &2.inserted_at)
      )

    cart = Ash.load!(cart, :active_checkout_session)

    assert cart.active_checkout_session.state == :open
    assert cart.active_checkout_session.id == second_checkout_session.id
  end

  test "Cart.expire_all_checkout_sessions/2 expires all checkout sessions associated with the cart",
       %{cart: cart} do
    cart =
      cart
      |> Cart.add_new_checkout_session!()
      |> Cart.add_new_checkout_session!()

    cart = Cart.expire_all_checkout_sessions!(cart)

    assert_no_open_checkout_sessions(cart)
  end

  describe "static products" do
    setup %{cart: cart} do
      product =
        %{
          handle: "test",
          type: :static,
          product_variants: [
            %{
              title: "Test",
              description: "Description",
              price_variants: [
                %{
                  price: Money.new(:USD, "39.99"),
                  compare_at_price: Money.new(:USD, "49.99")
                }
              ]
            }
          ]
        }
        |> Product.create!()

      display_product_variant = Product.display_product_variant!(product)

      cart = Cart.add_to_cart!(cart, %{product_variant: display_product_variant})

      %{
        product_variant: display_product_variant,
        cart: cart
      }
    end

    test "Cart.add_to_cart/1 adds a product variant to the cart and fills in price_variant_id when not passed",
         %{
           cart: cart,
           product_variant: product_variant
         } do
      %{product: product} = Ash.load!(product_variant, [:product])

      price_variant = ProductVariant.display_price_variant!(product_variant)

      [cart_item] = cart.cart_items

      assert cart_item.quantity == 1
      assert String.starts_with?(cart_item.display_id, product.handle)
      assert cart_item.price_variant_id == price_variant.id
    end

    test "Cart.empty?/1 returns false for a non-empty cart", %{
      cart: cart
    } do
      refute Cart.empty?(cart)
    end

    test "CartItem.update_quantity/3 expires all previous checkout sessions", %{
      cart: cart
    } do
      %{cart_items: [cart_item]} = cart

      CartItem.update_quantity(cart_item, %{quantity: cart_item.quantity + 1})

      assert_no_open_checkout_sessions(Cart.get_by_id!(cart.id))
    end

    # this is to make sure the checkout session always reflects the latest state of the cart
    test "Cart.add_to_cart/3 expires all previous checkout sessions", %{
      cart: cart,
      product_variant: product_variant
    } do
      {:ok, cart} = Cart.add_new_checkout_session(cart)

      {:ok, cart} =
        Cart.add_to_cart(cart, %{product_variant: product_variant})

      assert_no_open_checkout_sessions(cart)
    end

    test "Cart.add_to_cart/1 increments a cart tem's quantity if the product variant already exists in the cart",
         %{
           cart: cart,
           product_variant: product_variant
         } do
      for _ <- 1..4, reduce: cart do
        cart ->
          {:ok, cart} =
            Cart.add_to_cart(cart, %{product_variant: product_variant})

          cart
      end

      {:ok, cart} = Ash.load(cart, [:cart_items])

      assert [%CartItem{quantity: 5}] = cart.cart_items
    end

    test "CartItem.update_quantity/2 increments, decrements, and modifies quantity", %{
      cart: cart
    } do
      [cart_item] = cart.cart_items

      # increments
      {:ok, updated_cart_item} =
        CartItem.update_quantity(cart_item, %{quantity: cart_item.quantity + 1})

      assert updated_cart_item.quantity == cart_item.quantity + 1

      # decrements
      {:ok, updated_cart_item} =
        CartItem.update_quantity(updated_cart_item, %{quantity: updated_cart_item.quantity - 1})

      assert updated_cart_item.quantity == cart_item.quantity

      # arbitrary quantity
      {:ok, updated_cart_item} = CartItem.update_quantity(updated_cart_item, %{quantity: 20})
      assert updated_cart_item.quantity == 20

      # illegal values
      assert {:error, _error} = CartItem.update_quantity(updated_cart_item, %{quantity: 0})
      assert {:error, _error} = CartItem.update_quantity(updated_cart_item, %{quantity: -1})
    end

    test "CartItem.display_title/1 and CartItem.display_description/1 contains the correct product",
         %{
           cart: cart,
           product_variant: product_variant
         } do
      [cart_item] = cart.cart_items

      assert CartItem.display_title!(cart_item) == product_variant.title
      assert CartItem.display_description!(cart_item) == product_variant.description
    end

    test "Cart.contains?/3 returns true if a cart contains a product and false otherwise", %{
      cart: cart,
      product_variant: product_variant
    } do
      assert Cart.contains?(cart, :static, product_variant.id)
      refute Cart.contains?(cart, :static, "non-existent")
    end

    test "Cart.subtotal/1 contains correct subtotal", %{
      cart: cart
    } do
      new_product =
        %{
          handle: "test-2",
          type: :static,
          product_variants: [
            %{
              title: "Test 2",
              description: "Description",
              price_variants: [
                %{
                  price: Money.new(:USD, "0.01")
                }
              ]
            }
          ]
        }
        |> Product.create!()

      display_product_variant = Product.display_product_variant!(new_product)

      cart = Cart.add_to_cart!(cart, %{product_variant: display_product_variant})

      [_first_cart_item, second_cart_item] = cart.cart_items

      CartItem.update_quantity!(second_cart_item, %{quantity: 2})

      # reload to reflect cart item changes
      cart = Cart.get_by_id!(cart.id)

      subtotal = Cart.subtotal!(cart)

      assert Money.equal?(subtotal, Money.new(:USD, "40.01"))
    end
  end

  describe "Dynamic products" do
    for {type, resource} <- ProductType.dynamic_type_resource_pairs() do
      setup %{cart: cart} do
        product =
          %{
            handle: Atom.to_string(unquote(type)),
            type: unquote(type),
            product_variants: [
              %{
                title: "product_variant_title",
                description: "product_variant_description",
                price_variants: [
                  %{
                    price: Money.new(:USD, "39.99")
                  },
                  %{
                    price: Money.new(:USD, "49.99")
                  }
                ]
              }
            ]
          }
          |> Product.create!()

        display_product_variant = Product.display_product_variant!(product)

        dynamic_product = unquote(resource).create!()

        cart =
          Cart.add_to_cart!(
            cart,
            %{
              product_variant: display_product_variant,
              dynamic_product_id: dynamic_product.id,
              product_type: unquote(type)
            }
          )

        %{
          cart: cart,
          dynamic_product: dynamic_product,
          product_variant: display_product_variant
        }
      end

      test "Cart.add_to_cart/1 adds a product variant to the cart", %{
        cart: cart,
        dynamic_product: %{hash: dynamic_product_hash},
        product_variant: %{id: product_variant_id} = product_variant
      } do
        [cart_item] = cart.cart_items

        assert %{
                 quantity: 1,
                 product_variant_id: ^product_variant_id,
                 display_id: ^dynamic_product_hash
               } = cart_item

        # title and description should be fetched from the resource itself, not from the product variant
        refute CartItem.display_title!(cart_item) == product_variant.title
        refute CartItem.display_description!(cart_item) == product_variant.description
      end

      test "Cart.add_to_cart/1 increments a cart item's quantity if the product variant already exists in the cart",
           %{
             cart: cart,
             dynamic_product: dynamic_product,
             product_variant: %{id: product_variant_id} = product_variant
           } do
        cart =
          for _ <- 1..4, reduce: cart do
            cart ->
              cart =
                Cart.add_to_cart!(cart, %{
                  product_variant: product_variant,
                  dynamic_product_id: dynamic_product.id,
                  product_type: unquote(type)
                })

              cart
          end

        [cart_item] = cart.cart_items

        assert %{quantity: 5, product_variant_id: ^product_variant_id} = cart_item
      end

      test "Cart.contains?/3 returns true if a cart contains a product and false otherwise", %{
        cart: cart,
        dynamic_product: dynamic_product
      } do
        assert Cart.contains?(cart, unquote(type), dynamic_product.id)
        assert not Cart.contains?(cart, unquote(type), "non-existent")
      end
    end
  end

  defp assert_no_open_checkout_sessions(cart) do
    {:ok, cart} = Ash.load(cart, [:checkout_sessions])

    for checkout_session <- cart.checkout_sessions do
      # the state could be :complete, in which case it shouldn't become :expired
      assert checkout_session.state != :open
    end
  end
end
