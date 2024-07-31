defmodule Shopifex.Products.AttributeOption do
  use Ash.Resource,
    domain: Shopifex.Products,
    data_layer: AshPostgres.DataLayer

  postgres do
    repo Shopifex.Repo

    table "attribute_options"
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
  end

  attributes do
    uuid_primary_key :id

    attribute :value, :string, allow_nil?: false, public?: true
    attribute :text, :string, allow_nil?: false, public?: true
    attribute :additional_charge, AshMoney.Types.Money, allow_nil?: true, public?: true
  end

  relationships do
    belongs_to :attribute, Shopifex.Products.Attribute, public?: true
  end
end
