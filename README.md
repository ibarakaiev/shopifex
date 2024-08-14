# Shopifex

Shopifex is an example [Fireside](https://github.com/ibarakaiev/fireside)
component that implements e-commerce functionality. To install
it, make sure to add `:fireside` to your list of dependencies and run:

```
mix fireside.install shopifex@github:ibarakaiev/shopifex
```

## Admin panel

Shopifex enables `ash_admin`. If you use `Phoenix`, follow the
[`AshAdmin`](https://hexdocs.pm/ash_admin/getting-started-with-ash-admin.html)
tutorial to enable the admin routes in your app.

## Resources

### Products

`Product`s may have multiple `Attribute`s which may have several
`AttributeOption`s. Example: shoes may have two attributes, size and color,
which have many attribute options (size options and different colors).
Attribute options may also introduce an additional charge.

Additionally, each `Product` needs at least one `ProductVariant` which defines
a title, description, handle (displayed in the URL), etc. Each `ProductVariant`
in turn needs at least one `PriceVariant`, which defines a price. A
`PriceVariant` may belong to multiple `ProductVariants`, but not to multiple
products, and a `Product` may not have multiple identical `Price`s.

This architecture allows testing different titles and descriptions, as well
as different prices (independent of titles and descriptions).

`Product` has a `display_product_variant` function, which works as follows:
- if `product_variant_id` is passed, that product variant will be loaded.
- otherwise:
  - if `selected_product_variant_id` is set, that product variant will be used.
  - otherwise, the oldest existing product variant will be loaded.

`ProductVariant` has a similar `display_price_variant` function. Additionally,
it has a `compare_at_price` function, which returns the most expensive price
variant. This is useful when a discount is available, and the highest price
can be shown as the "original" price.

Additionally, `Product` has helper methods to retrieve the `title`,
`description`, and `price`, which all rely on the `display_product_variant`
(and have the same function signature).

A product can also be `:static` or `:dynamic`. If a product is `:dynamic`,
an entire new Ash resource may be used to implement it for complex use cases
such as [Memory Trivias by Memory+](https://memory.plus/products/memory-trivia)
which use Shopifex.

```mermaid
classDiagram
    class Attribute {
        UUID id
        update(String title, String alias)
        destroy()
        read()
        create(Map[] options, String title, String alias)
        add_options(Map[] options)
        by_id(UUID id)
        by_alias(String alias)
    }
    class AttributeOption {
        UUID id
        String value
        String text
        Money additional_charge
        UUID attribute_id
        Attribute attribute
        update(String value, String text, Money additional_charge, UUID attribute_id)
        create(String value, String text, Money additional_charge, UUID attribute_id)
        destroy()
        read()
    }
    class PriceVariant {
        UUID id
        Money price
        UUID product_id
        Product product
        read()
        create(Money price, UUID product_id)
        by_id(UUID id)
    }
    class Product {
        UUID id
        ProductStatus status
        String handle
        ProductType type
        UUID selected_product_variant_id
        ProductVariant selected_product_variant
        destroy()
        read()
        create(Map[] product_variants, Map[] attributes, String handle, ProductType type)
        add_product_variants(Map[] product_variants)
        add_attributes(Map[] attributes)
        select_display_product_variant(UUID selected_product_variant_id)
        update_status(ProductStatus status)
        by_id(UUID id)
        by_handle(String handle)
    }
    class ProductAttributes {
        update()
        create()
        destroy()
        read()
    }
    class ProductVariant {
        UUID id
        String alias
        String title
        String description
        String[] image_urls
        UUID selected_price_variant_id
        UUID product_id
        Product product
        PriceVariant selected_price_variant
        update(String title, String description, String alias, String[] image_urls)
        destroy()
        read()
        create(Map[] price_variants, String alias, String title, String description, ...)
        add_price_variant(Map[] price_variants)
        select_display_price_variant(UUID selected_price_variant_id)
        by_id(UUID id)
        by_alias_and_product_id(String alias, UUID product_id)
    }
    class ProductVariantPriceVariant {
        update()
        create()
        destroy()
        read()
    }

    Attribute -- AttributeOption
    Attribute -- Product
    Attribute -- ProductAttributes
    PriceVariant -- Product
    PriceVariant -- ProductVariant
    PriceVariant -- ProductVariantPriceVariant
    Product -- ProductAttributes
    Product -- ProductVariant
    ProductVariant -- ProductVariantPriceVariant
```

### Carts

A `Cart` contains multiple `CartItem`s which record what `ProductVariant` and
`PriceVariant` was used (and a `dynamic_product_id` if the product is dynamic).

Cart items are added with `Cart.add_cart_item`. If a cart item is already in
the cart, its quantity will be increased. An individual cart item's quantity
can be changed with `CartItem.update_quantity`.

`CartItem` implements several helper methods:
- `subtotal`: the price of a cart item (price of a product with all additional
  charges times the quantity).
- `compare_at_subtotal`: what the subtotal would have been if the compare-at
  price was used
- `display_title`: what title to display in the cart. If a cart
  item is associated with a dynamic product, a dynamic title will be used.
- `display_description`: same as above, but for description.

A `Cart` also has associated `CheckoutSession`s. It has two functions to aid
with creating and maintaining checkout sessions: 
- `add_new_checkout_session`: adds a new CheckoutSession and invalidates all
  previous ones.
- `expire_all_checkout_sessions`: invalidates all existing associated
  checkout sessions.

All changes are broadcasted to PubSub so that the cart stays as up-to-date as
possible if LiveView is used.
```mermaid
classDiagram
    class Cart {
        UUID id
        Atom state
        update(Atom state)
        create(Atom state)
        destroy()
        read()
        add_to_cart(Map cart_item)
        add_new_checkout_session()
        expire_all_checkout_sessions()
        complete_checkout()
        by_id(UUID id)
    }
    class CartItem {
        UUID id
        UUID cart_id
        UUID product_variant_id
        UUID price_variant_id
        Cart cart
        ProductVariant product_variant
        PriceVariant price_variant
        update()
        read()
        create_or_increment_quantity(Map product_variant, Map price_variant, ProductType product_type, UUID dynamic_product_id)
        update_quantity(Integer quantity)
        by_id(UUID id)
        destroy()
    }

    Cart -- CartItem
    Cart -- CheckoutSession
    CartItem -- PriceVariant
    CartItem -- ProductVariant
```

### Checkout
Shopifex doesn't implement checkout session functionality, but exposes a
`CheckoutSession` resource to make it easier to track active checkout sessions
and invalidate inactive ones if the cart's contents change. It is up to the end
user to implement checkout functionality, either via Stripe Checkout Sessions
or something else. For example, you may add a `StripeCheckoutSession`
(in a new `Stripe` Ash domain) that `belongs_to` a `CheckoutSession`.

```mermaid
classDiagram
    class CheckoutSession {
        UUID id
        UUID cart_id
        Atom state
        Cart cart
        create(UUID cart_id)
        read()
        by_id(UUID id)
        complete_checkout()
        expire()
    }

    Cart -- CheckoutSession
```

### Orders
Shopifex doesn't make assumptions about how orders are placed, tracked, and
fulfilled. It is recommended to create a new `Orders` domain which will contain
orders created from successful checkout sessions.
