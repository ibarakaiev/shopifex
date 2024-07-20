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
    assert {:ok, cart} = Ash.load(Cart.create(), [:cart_items, :checkout_sessions])

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
    {:ok, %{checkout_sessions: checkout_sessions}} =
      cart
      |> Cart.add_new_checkout_session!()
      |> Cart.add_new_checkout_session!()
      |> Ash.load(:checkout_sessions)

    [first_checkout_session, second_checkout_session] =
      Enum.sort(
        checkout_sessions,
        &NaiveDateTime.before?(&1.inserted_at, &2.inserted_at)
      )

    assert first_checkout_session.state == :expired
    assert second_checkout_session.state == :open
  end

  test ":active_checkout_session contains the correct active checkout session", %{
    cart: cart
  } do
    {:ok, %{checkout_sessions: checkout_sessions}} =
      cart
      |> Cart.add_new_checkout_session!()
      |> Cart.add_new_checkout_session!()
      |> Ash.load(:checkout_sessions)

    [_first_checkout_session, second_checkout_session] =
      Enum.sort(
        checkout_sessions,
        &NaiveDateTime.before?(&1.inserted_at, &2.inserted_at)
      )

    {:ok, cart} = Ash.load(cart, :active_checkout_session)

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
    setup do
      {:ok, product} =
        %{
          title: "Test",
          description: "Description",
          handle: "test",
          type: :static,
          default_product_variant: %{
            default_price_variant: %{
              price: Money.new(:USD, "39.99"),
              compare_at_price: Money.new(:USD, "49.99")
            }
          }
        }
        |> Product.create()
        |> Ash.load(:display_product_variant)

      %{
        product_variant: product.display_product_variant
      }
    end

    test "Cart.add_to_cart/1 adds a product variant to the cart", %{
      cart: cart,
      product_variant: product_variant
    } do
      {:ok, cart} =
        Cart.add_to_cart(cart, %{cart_item: %{product_variant: product_variant}})

      {:ok, cart} = Ash.load(cart, [:cart_items])

      {:ok, %ProductVariant{product: %Product{handle: product_handle}}} =
        Ash.load(product_variant, [:product])

      assert [%CartItem{quantity: 1, display_id: ^product_handle}] = cart.cart_items
    end

    test "Cart.empty?/1 returns false for a non-empty cart", %{
      cart: cart,
      product_variant: product_variant
    } do
      {:ok, cart} =
        Cart.add_to_cart(cart, %{cart_item: %{product_variant: product_variant}})

      refute Cart.empty?(cart)
    end

    test "CartItem.update_quantity/3 expires all previous checkout sessions", %{
      cart: cart,
      product_variant: product_variant
    } do
      {:ok, %{cart_items: [cart_item]} = cart} =
        Cart.add_to_cart(cart, %{cart_item: %{product_variant: product_variant}})

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
        Cart.add_to_cart(cart, %{cart_item: %{product_variant: product_variant}})

      assert_no_open_checkout_sessions(cart)
    end

    test "Cart.add_to_cart/1 increments a cart tem's quantity if the product variant already exists in the cart",
         %{
           cart: cart,
           product_variant: product_variant
         } do
      for _ <- 1..5, reduce: cart do
        cart ->
          {:ok, cart} =
            Cart.add_to_cart(cart, %{cart_item: %{product_variant: product_variant}})

          cart
      end

      {:ok, cart} = Ash.load(cart, [:cart_items])

      assert [%CartItem{quantity: 5}] = cart.cart_items
    end

    test "CartItem.update_quantity/2 increments, decrements, and modifies quantity", %{
      cart: cart,
      product_variant: product_variant
    } do
      {:ok, cart} =
        Cart.add_to_cart(cart, %{cart_item: %{product_variant: product_variant}})

      {:ok, cart} = Ash.load(cart, [:cart_items])
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

    test "Cart.contains?/3 returns true if a cart contains a product and false otherwise", %{
      cart: cart,
      product_variant: product_variant
    } do
      {:ok, cart} =
        Cart.add_to_cart(cart, %{cart_item: %{product_variant: product_variant}})

      Cart.contains?(cart, :static, product_variant.id)
      assert not Cart.contains?(cart, :static, "non-existent")
    end

    test "Cart.subtotal/1 contains correct subtotal", %{
      cart: cart,
      product_variant: product_variant
    } do
      {:ok, cart} =
        Cart.add_to_cart(cart, %{cart_item: %{product_variant: product_variant}})

      {:ok, new_product} =
        %{
          title: "Test 2",
          description: "Description",
          handle: "test-2",
          type: :static,
          default_product_variant: %{
            default_price_variant: %{
              price: Money.new(:USD, "0.01")
            }
          }
        }
        |> Product.create()
        |> Ash.load(:display_product_variant)

      {:ok, %{cart_items: [_first_cart_item, second_cart_item]} = cart} =
        Cart.add_to_cart(cart, %{
          cart_item: %{product_variant: new_product.display_product_variant}
        })

      CartItem.update_quantity!(second_cart_item, %{quantity: 2})

      subtotal = cart.id |> Cart.get_by_id!() |> Cart.subtotal!()

      assert Money.equal?(subtotal, Money.new(:USD, "40.01"))
    end
  end

  describe "Dynamic products" do
    for {type, resource} <- ProductType.dynamic_type_resource_pairs() do
      setup do
        {:ok, product} =
          %{
            title: Atom.to_string(unquote(type)),
            description: "Description",
            handle: Atom.to_string(unquote(type)),
            type: unquote(type),
            default_product_variant: %{
              default_price_variant: %{
                price: Money.new(:USD, "39.99"),
                compare_at_price: Money.new(:USD, "49.99")
              }
            }
          }
          |> Product.create()
          |> Ash.load(:display_product_variant)

        {:ok, dynamic_product} = unquote(resource).create()

        %{
          dynamic_product: dynamic_product,
          product_variant: product.display_product_variant
        }
      end

      test "Cart.add_to_cart/1 adds a product variant to the cart", %{
        cart: cart,
        dynamic_product: %{id: dynamic_product_id, hash: dynamic_product_hash} = dynamic_product,
        product_variant: %{id: product_variant_id} = product_variant
      } do
        {:ok, cart} =
          Cart.add_to_cart(cart, %{
            cart_item: %{
              product_variant: product_variant,
              dynamic_product_id: dynamic_product.id,
              product_type: unquote(type)
            }
          })

        assert [
                 %CartItem{
                   quantity: 1,
                   product_variant_id: ^product_variant_id,
                   display_product: %{id: ^dynamic_product_id},
                   display_id: ^dynamic_product_hash
                 }
               ] =
                 cart.cart_items
      end

      test "Cart.add_to_cart/1 increments a cart item's quantity if the product variant already exists in the cart",
           %{
             cart: cart,
             dynamic_product: %{id: dynamic_product_id} = dynamic_product,
             product_variant: %{id: product_variant_id} = product_variant
           } do
        for _ <- 1..5, reduce: cart do
          cart ->
            {:ok, cart} =
              Cart.add_to_cart(cart, %{
                cart_item: %{
                  product_variant: product_variant,
                  dynamic_product_id: dynamic_product.id,
                  product_type: unquote(type)
                }
              })

            cart
        end

        {:ok, cart} = Ash.load(cart, [:cart_items])

        assert [
                 %CartItem{
                   quantity: 5,
                   product_variant_id: ^product_variant_id,
                   display_product: %{id: ^dynamic_product_id}
                 }
               ] =
                 cart.cart_items
      end

      test "Cart.contains?/3 returns true if a cart contains a product and false otherwise", %{
        cart: cart,
        dynamic_product: %{id: dynamic_product_id} = dynamic_product,
        product_variant: product_variant
      } do
        {:ok, cart} =
          Cart.add_to_cart(cart, %{
            cart_item: %{
              product_variant: product_variant,
              dynamic_product_id: dynamic_product.id,
              product_type: unquote(type)
            }
          })

        assert Cart.contains?(cart, unquote(type), dynamic_product_id)
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
