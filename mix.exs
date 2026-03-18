defmodule Cldr.Messages.MixProject do
  use Mix.Project

  @version "2.0.0"

  def project do
    [
      app: :ex_cldr_messages,
      version: @version,
      elixir: "~> 1.12",
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
          ~w(inets jason mix cldr_utils decimal ex_cldr ex_cldr_numbers ex_cldr_units
          ex_cldr_currencies ex_cldr_dates_times ex_cldr_calendars ex_cldr_lists ex_money gettext)a
      ],
      compilers: maybe_elixir_make() ++ Mix.compilers(),
      make_makefile: "c_src/Makefile"
    ]
  end

  defp description do
    """
    Localized and internationalized message formatting using
    Unicode MessageFormat 2 (MF2) and legacy ICU Message Format,
    integrated with the ex_cldr family supporting over 700 locales
    """
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_cldr_numbers, "~> 2.34"},
      {:ex_cldr_lists, "~> 2.10"},
      {:ex_cldr_dates_times, "~> 2.22", optional: true},
      {:ex_money, "~> 5.9", optional: true},
      {:ex_cldr_units, "~> 3.18", optional: true},
      {:elixir_make, "~> 0.4", runtime: false, optional: true},
      {:nimble_parsec, "~> 1.0"},
      {:jason, "~> 1.1"},
      {:benchee, "~> 1.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", optional: true, only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.20", optional: true, runtime: false},
      {:gettext, "~> 0.21 or ~> 1.0", optional: true}
    ]
  end

  defp package do
    [
      maintainers: ["Kip Cole"],
      licenses: ["Apache-2.0"],
      links: links(),
      files: [
        "lib",
        "c_src",
        "config",
        "mix.exs",
        "README*",
        "CHANGELOG*",
        "LICENSE*",
        "MESSAGE_FORMAT*"
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
        "CHANGELOG.md",
        "MESSAGE_FORMAT_v2.md",
        "MESSAGE_FORMAT_v1.md"
      ],
      formatters: ["html", "markdown"],
      groups_for_modules: groups_for_modules(),
      skip_undefined_reference_warnings_on: ["changelog", "CHANGELOG.md", "README.md"]
    ]
  end

  def aliases do
    []
  end

  defp groups_for_modules do
    []
  end

  defp maybe_elixir_make do
    if mf2_nif_enabled?() do
      [:elixir_make]
    else
      []
    end
  end

  def mf2_nif_enabled? do
    String.downcase(System.get_env("CLDR_MESSAGES_MF2_NIF", "false")) == "true" or
      Application.get_env(:ex_cldr_messages, :mf2_nif, false) == true
  end

  defp elixirc_paths(:test), do: ["lib", "mix", "test", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "mix"]
  defp elixirc_paths(_), do: ["lib"]
end
