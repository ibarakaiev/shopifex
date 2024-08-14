defmodule Shopifex.FiresideComponent do
  def config do
    [
      name: :shopifex,
      version: 1,
      files: [
        required: [
          "lib/shopifex/products.ex",
          "lib/shopifex/products/**/*.{ex,exs}",
          "lib/shopifex/carts.ex",
          "lib/shopifex/carts/**/*.{ex,exs}",
          "lib/shopifex/checkouts.ex",
          "lib/shopifex/checkouts/**/*.{ex,exs}",
          "test/shopifex/**/*_test.{ex,exs}"
        ],
        optional: [
          "lib/shopifex_web/endpoint.ex"
        ]
      ]
    ]
  end

  def setup(igniter) do
    otp_app = Igniter.Project.Application.app_name()

    [Shopifex.Products, Shopifex.Carts, Shopifex.Checkouts]
    |> Enum.reduce(igniter, fn domain, igniter ->
      Igniter.Project.Config.configure(
        igniter,
        "config.exs",
        otp_app,
        [:ash_domains],
        [domain],
        updater: fn zipper ->
          Igniter.Code.List.append_new_to_list(zipper, domain)
        end
      )
    end)
    |> Igniter.Project.Config.configure_new(
      "config.exs",
      otp_app,
      [:shopifex_dynamic_products],
      %{}
    )
    |> Ash.Igniter.codegen("setup_shopifex")
    |> Igniter.add_notice("Make sure to run `mix ash.migrate`.")
  end
end
