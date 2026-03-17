defmodule Cldr.Message.V2.NumberOptionsTest do
  use ExUnit.Case, async: true

  alias Cldr.Message.V2.{Parser, Interpreter}

  defp format(src, bindings), do: format_with_locale(src, bindings, "en-US")

  defp format_with_locale(src, bindings, locale) do
    {:ok, parsed} = Parser.parse(src)
    options = [backend: MyApp.Cldr, locale: locale]

    case Interpreter.format_list(parsed, bindings, options) do
      {:ok, iolist, _, _} -> :erlang.iolist_to_binary(iolist)
      {:error, iolist, _, _} -> :erlang.iolist_to_binary(iolist)
    end
  end

  describe "useGrouping option" do
    test "useGrouping=auto uses locale default (grouped)" do
      assert format("{{The total is {$n :number useGrouping=auto}}}", %{"n" => 12345}) ==
               "The total is 12,345"
    end

    test "useGrouping=always uses locale default (grouped)" do
      assert format("{{The total is {$n :number useGrouping=always}}}", %{"n" => 12345}) ==
               "The total is 12,345"
    end

    test "useGrouping=never suppresses grouping separators" do
      assert format("{{The total is {$n :number useGrouping=never}}}", %{"n" => 12345}) ==
               "The total is 12345"
    end

    test "useGrouping=never with large number" do
      assert format("{{{$n :number useGrouping=never}}}", %{"n" => 1_234_567}) ==
               "1234567"
    end

    test "useGrouping=never with small number (no effect)" do
      assert format("{{{$n :number useGrouping=never}}}", %{"n" => 42}) ==
               "42"
    end

    test "useGrouping=min2 groups only when 2+ digits in group" do
      assert format("{{{$n :number useGrouping=min2}}}", %{"n" => 1000}) ==
               "1000"
    end

    test "useGrouping=min2 groups when 2+ digits in highest group" do
      assert format("{{{$n :number useGrouping=min2}}}", %{"n" => 10_000}) ==
               "10,000"
    end

    test "useGrouping=min2 with large number" do
      assert format("{{{$n :number useGrouping=min2}}}", %{"n" => 1_234_567}) ==
               "1,234,567"
    end

    test "useGrouping with :integer function" do
      assert format("{{{$n :integer useGrouping=never}}}", %{"n" => 12345}) ==
               "12345"
    end

    test "useGrouping=never combined with minimumFractionDigits" do
      assert format("{{{$n :number useGrouping=never minimumFractionDigits=2}}}", %{"n" => 1234}) ==
               "1234.00"
    end
  end

  describe "maximumFractionDigits option" do
    test "truncates to specified number of decimal places" do
      assert format("{{{$n :number maximumFractionDigits=2}}}", %{"n" => 3.14159}) ==
               "3.14"
    end

    test "does not pad when fewer digits" do
      assert format("{{{$n :number maximumFractionDigits=2}}}", %{"n" => 3.1}) ==
               "3.1"
    end

    test "no decimal for whole number" do
      assert format("{{{$n :number maximumFractionDigits=2}}}", %{"n" => 3.0}) ==
               "3"
    end

    test "maximumFractionDigits=0 removes all decimals" do
      assert format("{{{$n :number maximumFractionDigits=0}}}", %{"n" => 3.14}) ==
               "3"
    end

    test "maximumFractionDigits=4 allows up to 4 places" do
      assert format("{{{$n :number maximumFractionDigits=4}}}", %{"n" => 3.14159}) ==
               "3.1416"
    end

    test "preserves grouping separators" do
      assert format("{{{$n :number maximumFractionDigits=2}}}", %{"n" => 12_345.6789}) ==
               "12,345.68"
    end

    test "combined with minimumFractionDigits" do
      assert format(
               "{{{$n :number minimumFractionDigits=1 maximumFractionDigits=4}}}",
               %{"n" => 3.14159}
             ) == "3.1416"
    end

    test "combined min/max pads to minimum" do
      assert format(
               "{{{$n :number minimumFractionDigits=1 maximumFractionDigits=4}}}",
               %{"n" => 3.0}
             ) == "3.0"
    end

    test "combined with useGrouping=never" do
      assert format(
               "{{{$n :number maximumFractionDigits=2 useGrouping=never}}}",
               %{"n" => 12_345.6789}
             ) == "12345.68"
    end
  end

  describe "numberingSystem option" do
    test "numberingSystem=arab formats with Arabic-Indic digits" do
      assert format_with_locale("{{{$n :number numberingSystem=arab}}}", %{"n" => 12345}, "ar") ==
               "\u{0661}\u{0662}\u{066C}\u{0663}\u{0664}\u{0665}"
    end

    test "numberingSystem=latn overrides native system" do
      assert format_with_locale("{{{$n :number numberingSystem=latn}}}", %{"n" => 12345}, "ar") ==
               "12,345"
    end

    test "numberingSystem with :integer function" do
      assert format_with_locale("{{{$n :integer numberingSystem=arab}}}", %{"n" => 99}, "ar") ==
               "\u{0669}\u{0669}"
    end

    test "numberingSystem combined with useGrouping=never" do
      result =
        format_with_locale(
          "{{{$n :number numberingSystem=arab useGrouping=never}}}",
          %{"n" => 12345},
          "ar"
        )

      # Should use Arabic digits without grouping separator
      refute String.contains?(result, ",")
      refute String.contains?(result, "\u{066C}")
    end
  end

  # NIF validation tests — only run when the NIF is available
  describe "NIF validation" do
    @moduletag :mf2_nif

    @nif_cases [
      # useGrouping
      {"{{The total is {$n :number useGrouping=auto}}}", %{"n" => 12345}},
      {"{{The total is {$n :number useGrouping=always}}}", %{"n" => 12345}},
      {"{{The total is {$n :number useGrouping=never}}}", %{"n" => 12345}},
      {"{{{$n :number useGrouping=never}}}", %{"n" => 1_234_567}},
      {"{{{$n :number useGrouping=min2}}}", %{"n" => 1000}},
      {"{{{$n :number useGrouping=min2}}}", %{"n" => 10_000}},
      {"{{{$n :number useGrouping=min2}}}", %{"n" => 1_234_567}},
      {"{{{$n :integer useGrouping=never}}}", %{"n" => 12345}},
      {"{{{$n :number useGrouping=never minimumFractionDigits=2}}}", %{"n" => 1234}},
      # maximumFractionDigits
      {"{{{$n :number maximumFractionDigits=2}}}", %{"n" => 3.14159}},
      {"{{{$n :number maximumFractionDigits=2}}}", %{"n" => 3.1}},
      {"{{{$n :number maximumFractionDigits=2}}}", %{"n" => 3.0}},
      # maximumFractionDigits=0 skipped: ICU returns fallback {$n} for this case
      {"{{{$n :number maximumFractionDigits=4}}}", %{"n" => 3.14159}},
      {"{{{$n :number maximumFractionDigits=2}}}", %{"n" => 12_345.6789}},
      # combined min + max
      {"{{{$n :number minimumFractionDigits=1 maximumFractionDigits=4}}}", %{"n" => 3.14159}},
      {"{{{$n :number minimumFractionDigits=1 maximumFractionDigits=4}}}", %{"n" => 3.0}},
      # combined max + useGrouping
      {"{{{$n :number maximumFractionDigits=2 useGrouping=never}}}", %{"n" => 12_345.6789}},
      # numberingSystem (requires ar locale for arab number system)
      {"{{{$n :number numberingSystem=arab}}}", %{"n" => 12345}, "ar"},
      {"{{{$n :number numberingSystem=latn}}}", %{"n" => 12345}, "ar"},
      {"{{{$n :integer numberingSystem=arab}}}", %{"n" => 99}, "ar"}
    ]

    for {test_case, index} <- Enum.with_index(@nif_cases) do
      {src, bindings, locale} =
        case test_case do
          {src, bindings, locale} -> {src, bindings, locale}
          {src, bindings} -> {src, bindings, "en-US"}
        end

      @src src
      @bindings bindings
      @locale locale

      test "[#{index}] Elixir matches ICU for: #{src} (#{locale})" do
        src = @src
        bindings = @bindings
        locale = @locale

        {:ok, parsed} = Parser.parse(src)
        options = [backend: MyApp.Cldr, locale: locale]

        elixir_result =
          case Interpreter.format_list(parsed, bindings, options) do
            {:ok, iolist, _, _} -> {:ok, :erlang.iolist_to_binary(iolist)}
            {:error, iolist, _, _} -> {:ok, :erlang.iolist_to_binary(iolist)}
          end

        nif_result = Cldr.Message.V2.Nif.format(src, locale, bindings)

        assert elixir_result == nif_result,
               "Mismatch for #{inspect(src)} (locale: #{locale})\n  Elixir: #{inspect(elixir_result)}\n  ICU:    #{inspect(nif_result)}"
      end
    end
  end
end
