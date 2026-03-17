defmodule Cldr.Message.V2.Print do
  @moduledoc """
  Converts a MessageFormat 2 AST back to its canonical string form.

  Used by `Cldr.Message.canonical_message/2` for V2 messages.
  """
  import Kernel, except: [to_string: 1]

  @doc """
  Converts a parsed MF2 AST back to a canonical message string.

  ## Arguments

  * `ast` is a parsed MF2 message AST as returned by
    `Cldr.Message.V2.Parser.parse/1`.

  * `options` is a keyword list of options (currently unused
    but reserved for future use).

  ## Returns

  * A canonical message string.

  """
  @spec to_string(list() | tuple(), Keyword.t()) :: String.t()

  def to_string(ast, options \\ [])

  def to_string(ast, options) when is_list(options) do
    ast
    |> to_iolist(Map.new(options))
    |> :erlang.iolist_to_binary()
  end

  # ── Top-level ───────────────────────────────────────────────────

  defp to_iolist(parts, opts) when is_list(parts) do
    Enum.map(parts, &to_iolist(&1, opts))
  end

  defp to_iolist({:complex, declarations, body}, opts) do
    decls = Enum.map(declarations, &to_iolist(&1, opts))
    body_io = to_iolist(body, opts)
    [decls, body_io]
  end

  defp to_iolist({:quoted_pattern, parts}, opts) do
    ["{{", Enum.map(parts, &to_iolist(&1, opts)), "}}"]
  end

  defp to_iolist({:match, selectors, variants}, opts) do
    sel_io = Enum.map(selectors, fn {:variable, name} -> [" $", name] end)
    var_io = Enum.map(variants, &to_iolist(&1, opts))
    [".match", sel_io, "\n", Enum.intersperse(var_io, "\n")]
  end

  defp to_iolist({:variant, keys, pattern}, opts) do
    keys_io =
      Enum.map(keys, fn
        :catchall -> "*"
        key -> key_to_iolist(key)
      end)
      |> Enum.intersperse(" ")

    [keys_io, " ", to_iolist(pattern, opts)]
  end

  # ── Declarations ────────────────────────────────────────────────

  defp to_iolist({:input, expr}, opts) do
    [".input ", expression_to_iolist(expr, opts), "\n"]
  end

  defp to_iolist({:local, {:variable, name}, expr}, opts) do
    [".local $", name, " = ", expression_to_iolist(expr, opts), "\n"]
  end

  # ── Pattern parts ───────────────────────────────────────────────

  defp to_iolist({:text, text}, _opts) do
    escape_text(text)
  end

  defp to_iolist({:escape, char}, _opts) do
    ["\\", char]
  end

  defp to_iolist({:expression, _, _, _} = expr, opts) do
    expression_to_iolist(expr, opts)
  end

  defp to_iolist({:markup_open, name, options, attrs}, _opts) do
    ["{#", identifier_to_iolist(name), options_to_iolist(options), attrs_to_iolist(attrs), "}"]
  end

  defp to_iolist({:markup_close, name, options, attrs}, _opts) do
    ["{/", identifier_to_iolist(name), options_to_iolist(options), attrs_to_iolist(attrs), "}"]
  end

  defp to_iolist({:markup_standalone, name, options, attrs}, _opts) do
    ["{#", identifier_to_iolist(name), options_to_iolist(options), attrs_to_iolist(attrs), " /}"]
  end

  # ── Expressions ─────────────────────────────────────────────────

  defp expression_to_iolist({:expression, operand, func, attrs}, _opts) do
    parts = [
      operand_to_iolist(operand),
      func_to_iolist(func),
      attrs_to_iolist(attrs)
    ]

    ["{", Enum.reject(parts, &(&1 == [])), "}"]
  end

  defp operand_to_iolist(nil), do: []
  defp operand_to_iolist({:variable, name}), do: ["$", name]
  defp operand_to_iolist({:literal, value}), do: ["|", escape_quoted(value), "|"]
  defp operand_to_iolist({:number_literal, value}), do: [value]

  defp func_to_iolist(nil), do: []

  defp func_to_iolist({:function, name, opts}) do
    [" :", identifier_to_iolist(name), options_to_iolist(opts)]
  end

  defp options_to_iolist([]), do: []

  defp options_to_iolist(opts) do
    Enum.map(opts, fn {:option, name, value} ->
      [" ", name, "=", value_to_iolist(value)]
    end)
  end

  defp attrs_to_iolist([]), do: []

  defp attrs_to_iolist(attrs) do
    Enum.map(attrs, fn
      {:attribute, name, nil} -> [" @", name]
      {:attribute, name, value} -> [" @", name, "=", value_to_iolist(value)]
    end)
  end

  defp value_to_iolist({:variable, name}), do: ["$", name]
  defp value_to_iolist({:literal, value}), do: ["|", escape_quoted(value), "|"]
  defp value_to_iolist({:number_literal, value}), do: [value]

  defp key_to_iolist({:literal, value}), do: ["|", escape_quoted(value), "|"]
  defp key_to_iolist({:number_literal, value}), do: [value]

  defp identifier_to_iolist({:namespace, ns, name}), do: [ns, ":", name]
  defp identifier_to_iolist(name) when is_binary(name), do: [name]

  # ── Escaping ────────────────────────────────────────────────────

  defp escape_text(text) do
    text
    |> String.replace("\\", "\\\\")
    |> String.replace("{", "\\{")
    |> String.replace("}", "\\}")
  end

  defp escape_quoted(text) do
    text
    |> String.replace("\\", "\\\\")
    |> String.replace("|", "\\|")
  end
end
