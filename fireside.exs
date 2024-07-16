defmodule Shopifex.Fireside do
  def config do
    %{
      lib: [
        "lib/shopifex/products.ex",
        "lib/shopifex/products/**/*.{ex,exs}"
      ],
      overwritable: ["lib/shopifex/products/definitions.ex"],
      tests: [
        "test/shopifex/**/*_test.{ex,exs}"
      ],
      test_supports: [
        "test/support/products_factory.ex"
      ]
    }
  end

  def setup(igniter) do
    otp_app = Igniter.Project.Application.app_name()

    imported_ash_domains = [Shopifex.Products]

    igniter
    |> Igniter.Project.Config.configure(
      "config.exs",
      otp_app,
      [:ash_domains],
      imported_ash_domains,
      updater: fn zipper ->
        Igniter.Code.List.append_new_to_list(zipper, imported_ash_domains)
      end
    )
  end
end
