defmodule Cldr.Message.V2.InterpreterValidationTest do
  use ExUnit.Case, async: false

  @moduletag :mf2_nif

  alias Cldr.Message.V2.{Nif, Parser, Interpreter}

  @fixtures_dir Path.join([__DIR__, "..", "fixtures", "mf2"])

  # ── Helpers ───────────────────────────────────────────────────

  defp build_bindings(nil), do: %{}
  defp build_bindings(params) when is_list(params) do
    Map.new(params, fn %{"name" => name, "value" => value} -> {name, value} end)
  end

  defp elixir_format(src, params, locale) do
    bindings = build_bindings(params)

    with {:ok, parsed} <- Parser.parse(src) do
      options = [backend: MyApp.Cldr, locale: locale]
      case Interpreter.format_list(parsed, bindings, options) do
        {:ok, iolist, _, _} -> {:ok, :erlang.iolist_to_binary(iolist)}
        {:error, iolist, _, _} -> {:ok, :erlang.iolist_to_binary(iolist)}
      end
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

  defp nif_format(src, params, locale) do
    bindings = build_bindings(params)
    locale_str = if is_binary(locale), do: locale, else: Kernel.to_string(locale)
    Nif.format(src, locale_str, bindings)
  rescue
    e -> {:error, Exception.message(e)}
  end

  # ── Load all test fixtures ────────────────────────────────────

  defp load_fixture(path) do
    path
    |> File.read!()
    |> Jason.decode!()
  end

  defp load_tests(relative_path) do
    path = Path.join(@fixtures_dir, relative_path)
    data = load_fixture(path)
    locale = get_in(data, ["defaultTestProperties", "locale"]) || "en-US"

    data
    |> Map.get("tests", [])
    |> Enum.with_index()
    |> Enum.map(fn {test_case, index} -> Map.put(test_case, "_index", index) |> Map.put("_locale", locale) end)
  end

  # ── Comprehensive validation report ───────────────────────────

  describe "comprehensive Elixir vs ICU validation" do
    test "compare all formattable test cases and report differences" do
      fixtures = [
        {"syntax.json", load_tests("syntax.json")},
        {"functions/number.json", load_tests("functions/number.json")},
        {"functions/integer.json", load_tests("functions/integer.json")},
        {"functions/string.json", load_tests("functions/string.json")}
      ]

      {matches, differences, errors} =
        Enum.reduce(fixtures, {[], [], []}, fn {fixture_name, tests}, {m, d, e} ->
          Enum.reduce(tests, {m, d, e}, fn test_case, {m_acc, d_acc, e_acc} ->
            src = test_case["src"]
            exp = test_case["exp"]
            params = test_case["params"]
            has_errors = test_case["expErrors"] != nil
            index = test_case["_index"]
            locale = test_case["_locale"]

            if src == nil or exp == nil or has_errors do
              {m_acc, d_acc, e_acc}
            else
              elixir_result = elixir_format(src, params, locale)
              nif_result = nif_format(src, params, locale)

              case {elixir_result, nif_result} do
                {{:ok, elixir_out}, {:ok, nif_out}} when elixir_out == nif_out ->
                  {[{fixture_name, index, src, elixir_out, exp} | m_acc], d_acc, e_acc}

                {{:ok, elixir_out}, {:ok, nif_out}} ->
                  jaro = String.jaro_distance(elixir_out, nif_out)
                  diff = %{
                    fixture: fixture_name,
                    index: index,
                    src: src,
                    elixir: elixir_out,
                    nif: nif_out,
                    expected: exp,
                    jaro: Float.round(jaro, 4)
                  }
                  {m_acc, [diff | d_acc], e_acc}

                other ->
                  err = %{fixture: fixture_name, index: index, src: src, result: other}
                  {m_acc, d_acc, [err | e_acc]}
              end
            end
          end)
        end)

      matches = Enum.reverse(matches)
      differences = Enum.reverse(differences)
      errors = Enum.reverse(errors)

      total = length(matches) + length(differences) + length(errors)

      # ── Categorize differences ──────────────────────────────
      categories = categorize_differences(differences)

      # ── Print report ────────────────────────────────────────
      IO.puts("\n" <> String.duplicate("=", 70))
      IO.puts("MF2 Interpreter Validation: Elixir vs ICU NIF")
      IO.puts(String.duplicate("=", 70))
      IO.puts("")
      IO.puts("Total test cases compared:  #{total}")
      IO.puts("  Exact matches:            #{length(matches)} (#{pct(length(matches), total)})")
      IO.puts("  Differences:              #{length(differences)} (#{pct(length(differences), total)})")
      IO.puts("  Errors:                   #{length(errors)} (#{pct(length(errors), total)})")
      IO.puts("")

      if differences != [] do
        IO.puts("Difference categories:")

        for {category, diffs} <- categories do
          IO.puts("  #{category}: #{length(diffs)} cases")

          for diff <- Enum.take(diffs, 3) do
            IO.puts("    src: #{inspect(diff.src)}")
            IO.puts("      Elixir: #{inspect(diff.elixir)}  ICU: #{inspect(diff.nif)}  Jaro: #{diff.jaro}")
          end

          if length(diffs) > 3, do: IO.puts("    ... and #{length(diffs) - 3} more")
          IO.puts("")
        end

        avg_jaro =
          differences
          |> Enum.map(& &1.jaro)
          |> then(fn jaros -> Enum.sum(jaros) / length(jaros) end)
          |> Float.round(4)

        IO.puts("Average Jaro similarity of differences: #{avg_jaro}")
      end

      IO.puts(String.duplicate("=", 70))

      # ── Assert a reasonable match rate ──────────────────────
      match_rate = length(matches) / max(total, 1) * 100

      assert match_rate > 50,
        "Match rate too low: #{Float.round(match_rate, 1)}% (#{length(matches)}/#{total})"
    end
  end

  # ── Categorize ────────────────────────────────────────────────

  defp categorize_differences(diffs) do
    diffs
    |> Enum.group_by(fn diff ->
      cond do
        # Markup: our interpreter renders tags, ICU drops them
        String.contains?(diff.src, "{#") or String.contains?(diff.src, "{/") ->
          "Markup rendering (Elixir renders tags, ICU drops)"

        # Unbound variable: we produce empty, ICU produces {$name} fallback
        diff.nif =~ ~r/\{\$\w+\}/ and diff.elixir == "" ->
          "Unbound variable fallback ({$var} vs empty)"

        # Unknown function: ICU falls back to {operand}, we produce empty or formatted
        diff.nif =~ ~r/\{[:\$]/ and diff.elixir == "" ->
          "Unknown/custom function fallback"

        # Number formatting differences
        diff.src =~ ~r/:number|:integer|:percent/ and diff.elixir != "" and diff.nif != "" ->
          "Number formatting precision"

        # Unicode normalization
        String.contains?(diff.src, <<0x1E0C::utf8>>) or
        String.contains?(diff.src, <<0x0323::utf8>>) or
        String.contains?(diff.src, <<0x0307::utf8>>) ->
          "Unicode normalization (NFC)"

        # Literal name handling (e.g. 0E1 treated as name vs number)
        diff.src =~ ~r/\{[0-9][eE]/ ->
          "Literal name vs number ambiguity"

        true ->
          "Other"
      end
    end)
    |> Enum.sort_by(fn {_, diffs} -> -length(diffs) end)
  end

  defp pct(n, total) when total > 0, do: "#{Float.round(n / total * 100, 1)}%"
  defp pct(_, _), do: "0%"
end
