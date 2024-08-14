# Shopifex

Shopifex is an example [Fireside](https://github.com/ibarakaiev/fireside)
component that implements e-commerce functionality. To install
it, make sure to add `:fireside` to your list of dependencies and run:

```
mix fireside.install shopifex@github:ibarakaiev/shopifex
```

## Resources

### Products
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
