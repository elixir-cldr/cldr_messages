defmodule Cldr.Message.Parser do
  @moduledoc """
  Implements a parser for the [ICU Message format](http://userguide.icu-project.org/formatparse/messages)

  """

  import NimbleParsec
  import Cldr.Message.Parser.Combinator

  @rule :message

  def parse(input, allow_positional_args? \\ true) when is_binary(input) do
    with {:ok, parsed} <- unwrap(apply(__MODULE__, @rule, [input])) do
      parsed
      |> remove_nested_whitespace()
      |> maybe_allow_positional_args(allow_positional_args?)
    else
      {:ok, _result, rest} ->
        {:error,
         {Cldr.Message.ParseError, "Couldn't parse message. Error detected at #{inspect(rest)}"}}
    end
  rescue
    exception in [Cldr.Message.ParseError] ->
      {:error, {Cldr.Message.ParseError, exception.message}}
  end

  defparsec :message, message()
  defparsec :plural_message, plural_message()

  defp unwrap({:ok, acc, "", _, _, _}) when is_list(acc) do
    {:ok, acc}
  end

  defp unwrap({:ok, acc, rest, _, _, _}) when is_list(acc) do
    {:ok, acc, rest}
  end

  defp unwrap({:error, <<first::binary-size(1), reason::binary>>, rest, _, _, offset}) do
    {:error,
     {Cldr.Message.ParseError,
      "#{String.capitalize(first)}#{reason}. Could not parse the remaining #{inspect(rest)} " <>
        "starting at position #{offset + 1}"}}
  end

  defp remove_nested_whitespace([maybe_complex]) do
    [remove_nested_whitespace(maybe_complex)]
  end

  defp remove_nested_whitespace([{complex_arg, _arg, _selects} = complex | rest])
       when complex_arg in [:plural, :select, :select_ordinal] do
    [remove_nested_whitespace(complex), remove_nested_whitespace(rest)]
  end

  defp remove_nested_whitespace([head | rest]) do
    [head | remove_nested_whitespace(rest)]
  end

  defp remove_nested_whitespace({complex_arg, arg, selects})
       when complex_arg in [:select, :plural, :select_ordinal] do
    selects =
      Enum.map(selects, fn
        {k, [{:literal, string} = literal, {:select, _, _} = select | other]} ->
          if is_whitespace?(string), do: {k, [select | other]}, else: [literal, select | other]

        {k, [{:literal, string} = literal, {:plural, _, _, _} = plural | other]} ->
          if is_whitespace?(string), do: {k, [plural | other]}, else: [literal, plural | other]

        {k, [{:literal, string} = literal, {:select_ordinal, _, _} = select | other]} ->
          if is_whitespace?(string), do: {k, [select | other]}, else: [literal, select | other]

        other ->
          other
      end)
      |> Map.new()

    {complex_arg, arg, selects}
  end

  defp remove_nested_whitespace(other) do
    other
  end

  defp is_whitespace?(<<" ", rest::binary>>) do
    is_whitespace?(rest)
  end

  defp is_whitespace?(<<"\n", rest::binary>>) do
    is_whitespace?(rest)
  end

  defp is_whitespace?(<<"\t", rest::binary>>) do
    is_whitespace?(rest)
  end

  defp is_whitespace?(<<_char::bytes-1, _rest::binary>>) do
    false
  end

  defp is_whitespace?("") do
    true
  end

  defp maybe_allow_positional_args(parsed, allow_positional_args?)
      when allow_positional_args? != false do
    {:ok, parsed}
  end

  defp maybe_allow_positional_args(parsed, _allow_positional_args?) do
    has_positional_args? =
      parsed
      |> Cldr.Message.bindings()
      |> Enum.any?(&is_integer/1)

    if has_positional_args? do
      {:error,
        {Cldr.Message.PositionalArgsNotPermitted, "Positional arguments are not permitted"}}
    else
      {:ok, parsed}
    end
  end
end
