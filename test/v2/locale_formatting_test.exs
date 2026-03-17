defmodule Cldr.Message.V2.LocaleFormattingTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Tests MF2 formatting across locales covering different scripts and
  numbering systems: en, fr, ja, he, th, ar, de.

  Where both the Elixir and NIF backends support a function, the test
  asserts that both produce the same output.
  """

  @locales ["en", "fr", "ja", "he", "th", "ar", "de"]

  defp format_elixir(message, bindings, locale) do
    Cldr.Message.format(message, bindings,
      backend: MyApp.Cldr,
      locale: locale,
      formatter_backend: :elixir
    )
  end

  defp format_nif(message, bindings, locale) do
    Cldr.Message.format(message, bindings,
      backend: MyApp.Cldr,
      locale: locale,
      formatter_backend: :nif
    )
  end

  # ── :number ──────────────────────────────────────────────────────

  describe ":number formatting across locales" do
    test "integer value" do
      message = "{{{$n :number}}}"
      bindings = %{"n" => 1234}

      expected = %{
        "en" => "1,234",
        "fr" => "1\u202F234",
        "ja" => "1,234",
        "he" => "1,234",
        "th" => "1,234",
        "ar" => "1,234",
        "de" => "1.234"
      }

      for locale <- @locales do
        assert {:ok, result} = format_elixir(message, bindings, locale),
               ":number integer failed for locale #{locale}"

        assert result == expected[locale],
               ":number integer mismatch for #{locale}: got #{inspect(result)}, expected #{inspect(expected[locale])}"
      end
    end

    test "decimal value" do
      message = "{{{$n :number}}}"
      bindings = %{"n" => 1234.5}

      expected = %{
        "en" => "1,234.5",
        "fr" => "1\u202F234,5",
        "ja" => "1,234.5",
        "he" => "1,234.5",
        "th" => "1,234.5",
        "ar" => "1,234.5",
        "de" => "1.234,5"
      }

      for locale <- @locales do
        assert {:ok, result} = format_elixir(message, bindings, locale)

        assert result == expected[locale],
               ":number decimal mismatch for #{locale}: got #{inspect(result)}, expected #{inspect(expected[locale])}"
      end
    end

    @tag :mf2_nif
    test "Elixir and NIF produce identical output for :number" do
      message = "{{{$n :number}}}"

      cases = [
        %{"n" => 42},
        %{"n" => 1234},
        %{"n" => 1234.5},
        %{"n" => 1_000_000}
      ]

      for locale <- @locales, bindings <- cases do
        {:ok, elixir_result} = format_elixir(message, bindings, locale)
        {:ok, nif_result} = format_nif(message, bindings, locale)

        assert elixir_result == nif_result,
               ":number NIF mismatch for locale=#{locale}, n=#{inspect(bindings["n"])}: " <>
                 "elixir=#{inspect(elixir_result)}, nif=#{inspect(nif_result)}"
      end
    end

    test "negative numbers" do
      message = "{{{$n :number}}}"
      bindings = %{"n" => -42}

      for locale <- @locales do
        assert {:ok, result} = format_elixir(message, bindings, locale)

        assert String.contains?(result, "42"),
               "expected #{locale} result to contain 42, got #{inspect(result)}"
      end
    end
  end

  # ── :integer ─────────────────────────────────────────────────────

  describe ":integer formatting across locales" do
    test "integer value with grouping" do
      message = "{{{$n :integer}}}"
      bindings = %{"n" => 1234}

      expected = %{
        "en" => "1,234",
        "fr" => "1\u202F234",
        "ja" => "1,234",
        "he" => "1,234",
        "th" => "1,234",
        "ar" => "1,234",
        "de" => "1.234"
      }

      for locale <- @locales do
        assert {:ok, result} = format_elixir(message, bindings, locale)

        assert result == expected[locale],
               ":integer mismatch for #{locale}: got #{inspect(result)}, expected #{inspect(expected[locale])}"
      end
    end

    test "truncates decimal part" do
      message = "{{{$n :integer}}}"
      bindings = %{"n" => 3.7}

      for locale <- @locales do
        assert {:ok, result} = format_elixir(message, bindings, locale)

        assert String.contains?(result, "3"),
               ":integer truncation failed for #{locale}: got #{inspect(result)}"

        refute String.contains?(result, "7"),
               ":integer should truncate decimal for #{locale}: got #{inspect(result)}"
      end
    end

    @tag :mf2_nif
    test "Elixir and NIF produce identical output for :integer" do
      message = "{{{$n :integer}}}"
      bindings = %{"n" => 1234}

      for locale <- @locales do
        {:ok, elixir_result} = format_elixir(message, bindings, locale)
        {:ok, nif_result} = format_nif(message, bindings, locale)

        assert elixir_result == nif_result,
               ":integer NIF mismatch for #{locale}: " <>
                 "elixir=#{inspect(elixir_result)}, nif=#{inspect(nif_result)}"
      end
    end
  end

  # ── :percent ─────────────────────────────────────────────────────

  describe ":percent formatting across locales" do
    test "formats percentage" do
      message = "{{{$n :percent}}}"
      bindings = %{"n" => 0.85}

      for locale <- @locales do
        assert {:ok, result} = format_elixir(message, bindings, locale)

        assert String.contains?(result, "85"),
               ":percent failed for #{locale}: got #{inspect(result)}"

        assert String.contains?(result, "%"),
               ":percent missing % for #{locale}: got #{inspect(result)}"
      end
    end
  end

  # ── :currency ────────────────────────────────────────────────────

  describe ":currency formatting across locales" do
    test "formats USD" do
      message = "{{{$n :currency currency=USD}}}"
      bindings = %{"n" => 1234.56}

      for locale <- @locales do
        assert {:ok, result} = format_elixir(message, bindings, locale)

        assert String.contains?(result, "1"),
               ":currency failed for #{locale}: got #{inspect(result)}"

        assert String.contains?(result, "234"),
               ":currency failed for #{locale}: got #{inspect(result)}"

        assert String.contains?(result, "56"),
               ":currency failed for #{locale}: got #{inspect(result)}"
      end
    end

    test "locale-specific grouping and decimal separators" do
      message = "{{{$n :currency currency=EUR}}}"
      bindings = %{"n" => 1234.56}

      # Verify locale-appropriate formatting occurs (different grouping/decimal chars)
      {:ok, en} = format_elixir(message, bindings, "en")
      {:ok, de} = format_elixir(message, bindings, "de")
      {:ok, fr} = format_elixir(message, bindings, "fr")

      # English uses . for decimal
      assert String.contains?(en, ".")

      # German uses , for decimal
      assert String.contains?(de, ",")

      # French uses , for decimal
      assert String.contains?(fr, ",")
    end
  end

  # ── :unit ────────────────────────────────────────────────────────

  describe ":unit formatting across locales" do
    test "formats kilometers in each locale" do
      message = "{{{$d :unit unit=kilometer}}}"
      bindings = %{"d" => 3}

      for locale <- @locales do
        assert {:ok, result} = format_elixir(message, bindings, locale)
        assert String.contains?(result, "3"), ":unit failed for #{locale}: got #{inspect(result)}"
      end
    end

    test "unitDisplay=short" do
      message = "{{{$d :unit unit=kilometer unitDisplay=short}}}"
      bindings = %{"d" => 3}

      for locale <- @locales do
        assert {:ok, result} = format_elixir(message, bindings, locale)

        assert String.contains?(result, "3"),
               ":unit short failed for #{locale}: got #{inspect(result)}"
      end
    end

    test "unitDisplay=narrow" do
      message = "{{{$d :unit unit=kilometer unitDisplay=narrow}}}"
      bindings = %{"d" => 3}

      for locale <- @locales do
        assert {:ok, result} = format_elixir(message, bindings, locale)

        assert String.contains?(result, "3"),
               ":unit narrow failed for #{locale}: got #{inspect(result)}"
      end
    end
  end

  # ── :date ────────────────────────────────────────────────────────

  describe ":date formatting across locales" do
    test "formats date" do
      message = "{{{$d :date}}}"
      bindings = %{"d" => ~D[2024-03-15]}

      expected = %{
        "en" => "Mar 15, 2024",
        "fr" => "15 mars 2024",
        "ja" => "2024/03/15",
        "de" => "15.03.2024"
      }

      for {locale, expected_value} <- expected do
        assert {:ok, result} = format_elixir(message, bindings, locale)

        assert result == expected_value,
               ":date mismatch for #{locale}: got #{inspect(result)}, expected #{inspect(expected_value)}"
      end
    end

    test "all locales produce a valid date string" do
      message = "{{{$d :date}}}"
      bindings = %{"d" => ~D[2024-03-15]}

      for locale <- @locales do
        assert {:ok, result} = format_elixir(message, bindings, locale)

        assert String.contains?(result, "15"),
               ":date missing day for #{locale}: got #{inspect(result)}"

        assert String.contains?(result, "2024") or String.contains?(result, "24"),
               ":date missing year for #{locale}: got #{inspect(result)}"
      end
    end
  end

  # ── :datetime ────────────────────────────────────────────────────

  describe ":datetime formatting across locales" do
    test "formats datetime from string" do
      message = "{{{$dt :datetime}}}"
      bindings = %{"dt" => "2024-03-15T15:04:06"}

      for locale <- @locales do
        assert {:ok, result} = format_elixir(message, bindings, locale)

        assert String.contains?(result, "15"),
               ":datetime missing day for #{locale}: got #{inspect(result)}"
      end
    end

    test "formats datetime from struct" do
      message = "{{{$dt :datetime}}}"
      bindings = %{"dt" => ~N[2024-03-15 15:04:06]}

      for locale <- @locales do
        assert {:ok, result} = format_elixir(message, bindings, locale)
        assert String.length(result) > 0, ":datetime empty for #{locale}"
      end
    end
  end

  # ── :time ────────────────────────────────────────────────────────

  describe ":time formatting across locales" do
    test "formats time from NaiveDateTime" do
      message = "{{{$t :time}}}"
      bindings = %{"t" => ~N[2024-03-15 15:04:06]}

      for locale <- @locales do
        assert {:ok, result} = format_elixir(message, bindings, locale)
        assert String.length(result) > 0, ":time empty for #{locale}"
      end
    end
  end

  # ── :string ──────────────────────────────────────────────────────

  describe ":string formatting across locales" do
    test "passes string through unchanged in all locales" do
      message = "{{{$s :string}}}"
      bindings = %{"s" => "hello"}

      for locale <- @locales do
        assert {:ok, "hello"} = format_elixir(message, bindings, locale)
      end
    end
  end

  # ── numberingSystem option ───────────────────────────────────────

  describe "numberingSystem option across locales" do
    test "numberingSystem=arab uses Arabic-Indic digits" do
      message = "{{{$n :number numberingSystem=arab}}}"
      bindings = %{"n" => 123}

      {:ok, result} = format_elixir(message, bindings, "ar")

      refute String.contains?(result, "123"),
             "expected Arabic-Indic digits, got Latin: #{inspect(result)}"
    end

    test "numberingSystem=latn forces Latin digits in Arabic locale" do
      message = "{{{$n :number numberingSystem=latn}}}"
      bindings = %{"n" => 123}

      assert {:ok, "123"} = format_elixir(message, bindings, "ar")
    end

    test "numberingSystem=thai uses Thai digits" do
      message = "{{{$n :number numberingSystem=thai}}}"
      bindings = %{"n" => 123}

      {:ok, result} = format_elixir(message, bindings, "th")

      refute String.contains?(result, "123"),
             "expected Thai digits, got Latin: #{inspect(result)}"
    end

    @tag :mf2_nif
    test "Elixir and NIF agree on numberingSystem=arab" do
      message = "{{{$n :number numberingSystem=arab}}}"
      bindings = %{"n" => 123}

      {:ok, elixir_result} = format_elixir(message, bindings, "ar")
      {:ok, nif_result} = format_nif(message, bindings, "ar")

      assert elixir_result == nif_result,
             "numberingSystem=arab NIF mismatch: elixir=#{inspect(elixir_result)}, nif=#{inspect(nif_result)}"
    end
  end

  # ── .match with plural rules ─────────────────────────────────────

  describe ".match plural rules across locales" do
    test "cardinal plural selection" do
      message = ~S"""
      .input {$count :number}
      .match $count
        one {{{$count} item}}
        * {{{$count} items}}
      """

      # In English, 1 is "one", anything else is "other"
      assert {:ok, result} = format_elixir(message, %{"count" => 1}, "en")
      assert result =~ "item"
      refute result =~ "items"

      assert {:ok, result} = format_elixir(message, %{"count" => 5}, "en")
      assert result =~ "items"
    end

    test "Arabic has different plural categories" do
      # Arabic has: zero, one, two, few, many, other
      message = ~S"""
      .input {$count :integer}
      .match $count
        zero {{zero}}
        one {{one}}
        two {{two}}
        few {{few}}
        many {{many}}
        * {{other}}
      """

      assert {:ok, "zero"} = format_elixir(message, %{"count" => 0}, "ar")
      assert {:ok, "one"} = format_elixir(message, %{"count" => 1}, "ar")
      assert {:ok, "two"} = format_elixir(message, %{"count" => 2}, "ar")
      assert {:ok, "few"} = format_elixir(message, %{"count" => 3}, "ar")
      assert {:ok, "many"} = format_elixir(message, %{"count" => 11}, "ar")
      assert {:ok, "other"} = format_elixir(message, %{"count" => 100}, "ar")
    end

    test "French uses 'one' for 0 and 1" do
      message = ~S"""
      .input {$count :integer}
      .match $count
        one {{one}}
        * {{other}}
      """

      assert {:ok, "one"} = format_elixir(message, %{"count" => 0}, "fr")
      assert {:ok, "one"} = format_elixir(message, %{"count" => 1}, "fr")
      assert {:ok, "other"} = format_elixir(message, %{"count" => 2}, "fr")
    end

    test "Japanese has only 'other' category" do
      message = ~S"""
      .input {$count :integer}
      .match $count
        one {{one}}
        * {{other}}
      """

      assert {:ok, "other"} = format_elixir(message, %{"count" => 1}, "ja")
      assert {:ok, "other"} = format_elixir(message, %{"count" => 2}, "ja")
    end
  end

  # ── complex messages ─────────────────────────────────────────────

  describe "complex messages with mixed functions" do
    test "message with number and string across locales" do
      message = ~S"""
      .input {$name :string}
      .input {$count :number}
      {{Hello {$name}, you have {$count} items.}}
      """

      bindings = %{"name" => "Alice", "count" => 1234}

      for locale <- @locales do
        assert {:ok, result} = format_elixir(message, bindings, locale)
        assert String.contains?(result, "Alice"), "missing name for #{locale}: #{inspect(result)}"
        assert String.contains?(result, "234"), "missing number for #{locale}: #{inspect(result)}"
      end
    end
  end
end
