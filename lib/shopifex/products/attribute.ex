defmodule Shopifex.Products.Attribute do
  use Ash.Resource,
    domain: Shopifex.Products,
    data_layer: AshPostgres.DataLayer

  postgres do
    repo Shopifex.Repo

    table "attributes"
  end

  code_interface do
    define :create, action: :create
    define :update, action: :update
    define :add_options, action: :add_options, args: [:options]

    define :get_by_id, action: :by_id, args: [:id]
    define :get_by_alias, action: :by_alias, args: [:alias]
  end

  actions do
    defaults [:read, :destroy, update: [:title, :alias]]

    create :create do
      primary? true

      accept [:title, :alias]

      argument :options, {:array, :map}

      change manage_relationship(:options, on_lookup: :relate, on_no_match: :create)
    end

    update :add_options do
      require_atomic? false

      argument :options, {:array, :map}, allow_nil?: false

      change manage_relationship(:options, type: :create)
    end

    read :by_id do
      argument :id, :uuid, allow_nil?: false

      get? true

      filter expr(id == ^arg(:id))
    end

    read :by_alias do
      argument :alias, :string, allow_nil?: false

      get? true

      filter expr(alias == ^arg(:alias))
    end
  end

  preparations do
    prepare build(load: [:options])
  end

  attributes do
    uuid_primary_key :id

    attribute :title, :string, allow_nil?: false
    attribute :alias, :string, allow_nil?: false
  end

  relationships do
    many_to_many :products, Shopifex.Products.Product do
      through Shopifex.Products.ProductAttributes

      source_attribute_on_join_resource :attribute_id
      destination_attribute_on_join_resource :product_id
    end

    has_many :options, Shopifex.Products.AttributeOption
  end

  identities do
    identity :unique_alias, [:alias]
  end
end
