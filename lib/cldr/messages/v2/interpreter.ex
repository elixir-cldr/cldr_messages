defmodule Cldr.Message.V2.Interpreter do
  @moduledoc """
  Interprets a MessageFormat 2 AST and produces formatted output.

  The AST is produced by `Cldr.Message.V2.Parser` and uses tuples like
  `{:text, "..."}`, `{:expression, operand, function, attrs}`,
  `{:complex, declarations, body}`, `{:match, selectors, variants}`, etc.
  """

  @doc """
  Formats a parsed MF2 AST with the given bindings.

  ## Arguments

  * `ast` is a parsed MF2 message AST as returned by
    `Cldr.Message.V2.Parser.parse/1`.

  * `bindings` is a map or keyword list of variable bindings.
    String keys are NFC-normalized to match parser output.

  * `options` is a keyword list of options including `:backend`
    and `:locale`.

  ## Returns

  * `{:ok, iolist, bound, unbound}` on success, where `bound` is
    the list of variable names that were resolved and `unbound` is
    empty.

  * `{:error, iolist, bound, unbound}` when one or more variables
    could not be resolved. The `iolist` contains a partial result.

  """
  @spec format_list(list() | tuple(), map() | Keyword.t(), Keyword.t()) ::
          {:ok, list(), list(), list()} | {:error, list(), list(), list()}

  def format_list(ast, bindings \\ %{}, options \\ [])

  def format_list(ast, bindings, options) when is_list(bindings) do
    format_list(ast, Map.new(bindings), options)
  end

  def format_list(ast, bindings, options) when is_map(bindings) do
    bindings = normalize_binding_keys(bindings)
    do_format_list(ast, bindings, options)
  end

  defp do_format_list([{:complex, _, _} = complex], bindings, options) do
    do_format_list(complex, bindings, options)
  end

  defp do_format_list([{:match, _, _} = match], bindings, options) do
    do_format_list(match, bindings, options)
  end

  defp do_format_list([{:quoted_pattern, _} = qp], bindings, options) do
    do_format_list(qp, bindings, options)
  end

  defp do_format_list(ast, bindings, options) when is_list(ast) do
    # A simple message is a bare list of pattern parts
    case format_pattern(ast, bindings, options) do
      {:ok, iolist, bound, unbound} -> {:ok, iolist, bound, unbound}
      {:error, _, _, _} = err -> err
    end
  end

  defp do_format_list({:complex, declarations, body}, bindings, options) do
    {bindings, bound} = resolve_declarations(declarations, bindings, options)

    case body do
      {:quoted_pattern, parts} ->
        case format_pattern(parts, bindings, options) do
          {:ok, iolist, more_bound, unbound} -> {:ok, iolist, bound ++ more_bound, unbound}
          {:error, iolist, more_bound, unbound} -> {:error, iolist, bound ++ more_bound, unbound}
        end

      {:match, selectors, variants} ->
        evaluate_match(selectors, variants, bindings, options, bound)
    end
  end

  defp do_format_list({:quoted_pattern, parts}, bindings, options) do
    format_pattern(parts, bindings, options)
  end

  defp do_format_list({:match, selectors, variants}, bindings, options) do
    evaluate_match(selectors, variants, bindings, options, [])
  end

  # ── Pattern formatting ──────────────────────────────────────────

  defp format_pattern(parts, bindings, options) do
    {iolist, bound, unbound} =
      Enum.reduce(parts, {[], [], []}, fn part, {io_acc, bound_acc, unbound_acc} ->
        case format_part(part, bindings, options) do
          {:ok, result, new_bound} ->
            {[result | io_acc], new_bound ++ bound_acc, unbound_acc}

          {:unbound, var_name} ->
            {io_acc, bound_acc, [var_name | unbound_acc]}
        end
      end)

    iolist = iolist |> Enum.reverse()

    case unbound do
      [] -> {:ok, iolist, Enum.uniq(bound), []}
      _ -> {:error, iolist, Enum.uniq(bound), Enum.uniq(unbound)}
    end
  end

  defp format_part({:text, text}, _bindings, _options) do
    {:ok, text, []}
  end

  defp format_part({:escape, char}, _bindings, _options) do
    {:ok, char, []}
  end

  defp format_part({:expression, operand, func, _attrs}, bindings, options) do
    format_expression(operand, func, bindings, options)
  end

  defp format_part({:markup_open, _name, _options, _attrs}, _bindings, _options_kw) do
    {:ok, "", []}
  end

  defp format_part({:markup_close, _name, _options, _attrs}, _bindings, _options_kw) do
    {:ok, "", []}
  end

  defp format_part({:markup_standalone, _name, _options, _attrs}, _bindings, _options_kw) do
    {:ok, "", []}
  end

  # ── Expression formatting ───────────────────────────────────────

  defp format_expression(operand, func, bindings, options) do
    case resolve_operand(operand, bindings) do
      {:ok, value, bound_names} ->
        formatted = apply_function(value, func, Keyword.put(options, :bindings, bindings))
        {:ok, formatted, bound_names}

      {:unbound, name} ->
        {:unbound, name}
    end
  end

  defp resolve_operand(nil, _bindings) do
    {:ok, nil, []}
  end

  defp resolve_operand({:variable, name}, bindings) do
    case resolve_variable(name, bindings) do
      {:ok, value} -> {:ok, value, [name]}
      :error -> {:unbound, name}
    end
  end

  defp resolve_operand({:literal, value}, _bindings) do
    {:ok, value, []}
  end

  defp resolve_operand({:number_literal, value}, _bindings) do
    {:ok, value, []}
  end

  defp resolve_variable(name, bindings) when is_map(bindings) do
    # Try string key first, then atom key
    cond do
      Map.has_key?(bindings, name) ->
        {:ok, Map.get(bindings, name)}

      atom_key_exists?(name) && Map.has_key?(bindings, String.to_existing_atom(name)) ->
        {:ok, Map.get(bindings, String.to_existing_atom(name))}

      true ->
        :error
    end
  end

  defp atom_key_exists?(name) do
    String.to_existing_atom(name)
    true
  rescue
    ArgumentError -> false
  end

  defp apply_function(value, nil, _options) do
    to_string_value(value)
  end

  defp apply_function(value, {:function, name, func_options}, options) do
    bindings = Keyword.get(options, :bindings, %{})
    func_opts = resolve_func_options(func_options, bindings)
    format_with_function(name, value, func_opts, options)
  end

  defp format_with_function("number", value, func_opts, options) do
    number = ensure_number(value)
    cldr_opts = build_cldr_options(options, func_opts)
    format_number(number, cldr_opts)
  end

  defp format_with_function("integer", value, func_opts, options) do
    number = ensure_number(value) |> trunc()
    cldr_opts = build_cldr_options(options, func_opts)
    format_number(number, cldr_opts)
  end

  defp format_with_function("percent", value, func_opts, options) do
    number = ensure_number(value)
    cldr_opts = build_cldr_options(options, func_opts)
    cldr_opts = Keyword.put(cldr_opts, :format, :percent)
    format_number(number, cldr_opts)
  end

  defp format_with_function("currency", value, func_opts, options) do
    number = ensure_number(value)
    cldr_opts = build_cldr_options(options, func_opts)
    cldr_opts = Keyword.put(cldr_opts, :format, :currency)

    if currency = func_opts[:currency] do
      cldr_opts = Keyword.put(cldr_opts, :currency, currency)
      format_number(number, cldr_opts)
    else
      format_number(number, cldr_opts)
    end
  end

  defp format_with_function("string", value, _func_opts, _options) do
    to_string_value(value)
  end

  if Code.ensure_loaded?(Cldr.Date) do
    defp format_with_function("date", value, func_opts, options) do
      cldr_opts = build_cldr_options(options, func_opts)

      if style = func_opts[:style] do
        cldr_opts = Keyword.put(cldr_opts, :format, parse_date_style(style))
        Cldr.Date.to_string!(value, cldr_opts)
      else
        Cldr.Date.to_string!(value, cldr_opts)
      end
    end

    defp format_with_function("time", value, func_opts, options) do
      cldr_opts = build_cldr_options(options, func_opts)

      if style = func_opts[:style] do
        cldr_opts = Keyword.put(cldr_opts, :format, parse_date_style(style))
        Cldr.Time.to_string!(value, cldr_opts)
      else
        Cldr.Time.to_string!(value, cldr_opts)
      end
    end

    defp format_with_function("datetime", value, func_opts, options) do
      cldr_opts = build_cldr_options(options, func_opts)

      if style = func_opts[:style] do
        cldr_opts = Keyword.put(cldr_opts, :format, parse_date_style(style))
        Cldr.DateTime.to_string!(value, cldr_opts)
      else
        Cldr.DateTime.to_string!(value, cldr_opts)
      end
    end
  end

  defp format_with_function(_name, value, _func_opts, _options) do
    to_string_value(value)
  end

  # ── Declarations ────────────────────────────────────────────────

  defp resolve_declarations(declarations, bindings, options) do
    Enum.reduce(declarations, {bindings, []}, fn decl, {bindings_acc, bound_acc} ->
      case decl do
        {:input, {:expression, {:variable, name}, func, _attrs}} ->
          case resolve_variable(name, bindings_acc) do
            {:ok, value} ->
              formatted = apply_function(value, func, Keyword.put(options, :bindings, bindings_acc))
              bindings_acc = Map.put(bindings_acc, name, formatted)
              {bindings_acc, [name | bound_acc]}

            :error ->
              {bindings_acc, bound_acc}
          end

        {:local, {:variable, name}, {:expression, operand, func, _attrs}} ->
          case resolve_operand(operand, bindings_acc) do
            {:ok, value, _} ->
              formatted = apply_function(value, func, Keyword.put(options, :bindings, bindings_acc))
              bindings_acc = Map.put(bindings_acc, name, formatted)
              {bindings_acc, [name | bound_acc]}

            {:unbound, _} ->
              {bindings_acc, bound_acc}
          end
      end
    end)
  end

  # ── Match evaluation ────────────────────────────────────────────

  defp evaluate_match(selectors, variants, bindings, options, bound) do
    # Evaluate selector expressions to get values
    selector_values =
      Enum.map(selectors, fn {:variable, name} ->
        case resolve_variable(name, bindings) do
          {:ok, value} -> value
          :error -> nil
        end
      end)

    selector_names = Enum.map(selectors, fn {:variable, name} -> name end)

    # Find the best matching variant
    case find_best_variant(selector_values, variants, bindings, options) do
      {:ok, {:variant, _keys, {:quoted_pattern, parts}}} ->
        case format_pattern(parts, bindings, options) do
          {:ok, iolist, more_bound, unbound} ->
            {:ok, iolist, bound ++ selector_names ++ more_bound, unbound}

          {:error, iolist, more_bound, unbound} ->
            {:error, iolist, bound ++ selector_names ++ more_bound, unbound}
        end

      :error ->
        {:error, [], bound ++ selector_names, ["no matching variant"]}
    end
  end

  defp find_best_variant(selector_values, variants, bindings, options) do
    # Sort variants by specificity (fewer catchalls = more specific)
    sorted =
      variants
      |> Enum.filter(fn {:variant, keys, _} ->
        match_keys?(selector_values, keys, bindings, options)
      end)
      |> Enum.sort_by(fn {:variant, keys, _} ->
        Enum.count(keys, &(&1 == :catchall))
      end)

    case sorted do
      [best | _] -> {:ok, best}
      [] -> :error
    end
  end

  defp match_keys?(selector_values, keys, _bindings, _options) do
    if length(selector_values) != length(keys) do
      false
    else
      Enum.zip(selector_values, keys)
      |> Enum.all?(fn
        {_value, :catchall} -> true
        {value, {:literal, key_str}} -> match_value?(value, key_str)
        {value, {:number_literal, key_str}} -> match_value?(value, parse_number(key_str))
      end)
    end
  end

  defp match_value?(value, key) when is_integer(value) and is_integer(key) do
    value == key
  end

  defp match_value?(value, key) when is_float(value) and is_float(key) do
    value == key
  end

  defp match_value?(value, key) when is_number(value) and is_number(key) do
    value == key
  end

  defp match_value?(value, key) when is_binary(value) and is_binary(key) do
    value == key
  end

  defp match_value?(value, key) when is_number(value) and is_binary(key) do
    to_string_value(value) == key
  end

  defp match_value?(value, key) when is_binary(value) and is_number(key) do
    value == to_string_value(key)
  end

  defp match_value?(value, key) do
    to_string_value(value) == to_string_value(key)
  end

  # ── Helpers ─────────────────────────────────────────────────────

  defp resolve_func_options(func_options, bindings) do
    Enum.reduce(func_options, %{}, fn
      {:option, name, {:literal, value}}, acc ->
        Map.put(acc, String.to_atom(name), value)

      {:option, name, {:number_literal, value}}, acc ->
        Map.put(acc, String.to_atom(name), parse_number(value))

      {:option, name, {:variable, var_name}}, acc ->
        case resolve_variable(var_name, bindings) do
          {:ok, value} -> Map.put(acc, String.to_atom(name), value)
          :error -> Map.put(acc, String.to_atom(name), nil)
        end
    end)
  end

  defp build_cldr_options(options, func_opts) do
    {locale, backend} = Cldr.locale_and_backend_from(options)
    cldr_opts = [locale: locale, backend: backend]
    map_func_options(cldr_opts, func_opts)
  end

  @mf2_to_cldr_options %{
    minimumFractionDigits: :fractional_digits
  }

  defp map_func_options(cldr_opts, func_opts) do
    Enum.reduce(@mf2_to_cldr_options, cldr_opts, fn {mf2_key, cldr_key}, opts ->
      case Map.get(func_opts, mf2_key) do
        nil -> opts
        value -> Keyword.put(opts, cldr_key, ensure_integer(value))
      end
    end)
  end

  defp ensure_integer(value) when is_integer(value), do: value
  defp ensure_integer(value) when is_float(value), do: round(value)
  defp ensure_integer(value) when is_binary(value), do: String.to_integer(value)

  defp format_number(number, cldr_opts) do
    case Cldr.Number.to_string(number, cldr_opts) do
      {:ok, formatted} -> formatted
      {:error, _} -> to_string_value(number)
    end
  end

  defp ensure_number(value) when is_number(value), do: value
  defp ensure_number(value) when is_binary(value), do: parse_number(value)

  defp parse_number(str) when is_binary(str) do
    case Integer.parse(str) do
      {int, ""} ->
        int

      {_, _} ->
        case Float.parse(str) do
          {float, ""} -> float
          _ -> str
        end

      :error ->
        case Float.parse(str) do
          {float, ""} -> float
          _ -> str
        end
    end
  end

  defp parse_date_style(style) when is_binary(style) do
    case style do
      "short" -> :short
      "medium" -> :medium
      "long" -> :long
      "full" -> :full
      other -> other
    end
  end

  defp to_string_value(nil), do: ""
  defp to_string_value(value) when is_binary(value), do: value
  defp to_string_value(value) when is_integer(value), do: Integer.to_string(value)
  defp to_string_value(value) when is_float(value), do: Float.to_string(value)
  defp to_string_value(value), do: Kernel.to_string(value)

  defp normalize_binding_keys(bindings) when is_map(bindings) do
    Map.new(bindings, fn
      {key, value} when is_binary(key) ->
        {:unicode.characters_to_nfc_binary(key), value}

      {key, value} ->
        {key, value}
    end)
  end
end
