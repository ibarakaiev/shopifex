defmodule Shopifex.Products.Product.Changes.AddProductIdToProductVariants do
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    product_id =
      case Ash.Changeset.get_attribute(changeset, :id) do
        nil ->
          Ash.UUID.generate()

        product_id ->
          product_id
      end

    {:ok, product_variants} = Ash.Changeset.fetch_argument(changeset, :product_variants)

    changeset
    |> Ash.Changeset.force_change_attribute(:id, product_id)
    |> Ash.Changeset.force_set_argument(
      :product_variants,
      Enum.map(product_variants, fn product_variant ->
        Map.put(product_variant, :product_id, product_id)
      end)
    )
  end
end
