defmodule Shopifex.Products.ProductVariant.Changes.AddProductIdToPriceVariants do
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    product_id = Ash.Changeset.get_attribute(changeset, :product_id)
    {:ok, price_variants} = Ash.Changeset.fetch_argument(changeset, :price_variants)

    Ash.Changeset.force_set_argument(
      changeset,
      :price_variants,
      Enum.map(price_variants, &Map.put(&1, :product_id, product_id))
    )
  end
end
