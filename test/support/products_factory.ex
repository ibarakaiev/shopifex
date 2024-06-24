defmodule Shopifex.Products.Factory do
  @moduledoc false
  use Smokestack

  factory Shopifex.Products.Product do
    domain Shopifex.Products

    attribute :title, &Faker.Vehicle.make_and_model/0
    attribute :description, &Faker.Vehicle.body_style/0
    attribute :status, choose(Shopifex.Products.Enums.ProductStatus.values())
    attribute :handle, &Faker.Vehicle.vin/0
    attribute :type, choose(Shopifex.Products.Enums.ProductType.values())
  end

  factory Shopifex.Products.Product, :static do
    domain Shopifex.Products

    attribute :title, &Faker.Vehicle.make_and_model/0
    attribute :description, &Faker.Vehicle.body_style/0
    attribute :status, choose(Shopifex.Products.Enums.ProductStatus.values())
    attribute :handle, &Faker.Vehicle.vin/0
    attribute :type, constant(:static)
    attribute :image_urls, constant(["https://example.com/image.jpg"])
  end

  factory Shopifex.Products.ProductVariant do
    domain Shopifex.Products

    attribute :product_id, &Ash.UUID.generate/0

    attribute :alias, &Faker.Vehicle.body_style/0
  end

  factory Shopifex.Products.PriceVariant do
    domain Shopifex.Products

    attribute :price, constant(Money.new(:USD, "39.99"))
    attribute :compare_at_price, constant(Money.new(:USD, "49.99"))

    attribute :add_ons, constant(nil)

    attribute :product_variant_id, &Ash.UUID.generate/0
  end
end
