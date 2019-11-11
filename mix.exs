defmodule CldrMessages.MixProject do
  use Mix.Project

  @version "0.4.0"

  def project do
    [
      app: :ex_cldr_messages,
      version: @version,
      elixir: "~> 1.8",
      name: "Cldr Messages",
      source_url: "https://github.com/elixir-cldr/cldr_messages",
      docs: docs(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      test_coverage: [tool: ExCoveralls],
      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env()),
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore_warnings",
        plt_add_apps:
          ~w(inets jason mix ex_cldr ex_cldr_numbers ex_cldr_units ex_cldr_dates_times ex_cldr_calendars ex_money)a
      ],
      compilers: Mix.compilers()
    ]
  end

  defp description do
    """
    Localized and internationalized message formatting using the
    ICU message format integrated with  the ex_cldr family supporting
    over 500 locales
    """
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nimble_parsec, "~> 0.5"},
      {:ex_cldr, "~> 2.8"},
      {:ex_cldr_numbers, "~> 2.7"},
      {:jason, "~> 1.1"},
      {:ex_cldr_dates_times, "~> 2.2", optional: true},
      {:ex_money, "~> 4.0", optional: true},
      {:ex_cldr_units, "~> 2.0", optional: true},
      {:ex_cldr_lists, "~> 2.3", options: true},
      {:dialyxir, "~> 1.0.0-rc", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.20", only: [:dev, :test, :release]}
    ]
  end

  defp package do
    [
      maintainers: ["Kip Cole"],
      licenses: ["Apache 2.0"],
      links: links(),
      files: [
        "lib",
        "config",
        "mix.exs",
        "README*",
        "CHANGELOG*",
        "LICENSE*"
      ]
    ]
  end

  def links do
    %{
      "GitHub" => "https://github.com/elixir-cldr/cldr_messages",
      "Readme" => "https://github.com/elixir-cldr/cldr_messages/blob/v#{@version}/README.md",
      "Changelog" => "https://github.com/elixir-cldr/cldr_messages/blob/v#{@version}/CHANGELOG.md"
    }
  end

  def docs do
    [
      source_ref: "v#{@version}",
      main: "readme",
      logo: "logo.png",
      extras: [
        "README.md",
        "LICENSE.md",
        "CHANGELOG.md"
      ],
      groups_for_modules: groups_for_modules(),
      skip_undefined_reference_warnings_on: ["changelog"]
    ]
  end

  def aliases do
    []
  end

  defp groups_for_modules do
    []
  end

  defp elixirc_paths(:test), do: ["lib", "mix", "test", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "mix"]
  defp elixirc_paths(_), do: ["lib"]
end
