defmodule Cldr.Message.Parser do
  @moduledoc false

  import NimbleParsec
  import Cldr.Message.Parser.Combinator

  # message = messageText (argument messageText)*

  # argument = noneArg | simpleArg | complexArg

  # complexArg = choiceArg | pluralArg | selectArg | selectordinalArg
  # noneArg = '{' argNameOrNumber '}'
  # simpleArg = '{' argNameOrNumber ',' argType [',' argStyle] '}'
  # choiceArg = '{' argNameOrNumber ',' "choice" ',' choiceStyle '}'
  # pluralArg = '{' argNameOrNumber ',' "plural" ',' pluralStyle '}'
  # selectArg = '{' argNameOrNumber ',' "select" ',' selectStyle '}'
  # selectordinalArg = '{' argNameOrNumber ',' "selectordinal" ',' pluralStyle '}'

  # choiceStyle: see ChoiceFormat
  # pluralStyle: see PluralFormat
  # selectStyle: see SelectFormat

  # argNameOrNumber = argName | argNumber
  # argName = [^[[:Pattern_Syntax:][:Pattern_White_Space:]]]+
  # argNumber = '0' | ('1'..'9' ('0'..'9')*)
  # argType = "number" | "date" | "time" | "spellout" | "ordinal" | "duration"
  # argStyle = "short" | "medium" | "long" | "full" | "integer" | "currency" | "percent" | argStyleText | "::" argSkeletonText

  def parse(rule \\ :message, input) when is_atom(rule) and is_binary(input) do
    apply(__MODULE__, rule, [input])
    |> unwrap
  end

  defparsec :message, message()

  defp unwrap({:ok, acc, "", _, _, _}) when is_list(acc) do
    {:ok, acc}
  end

  defp unwrap({:ok, acc, rest, _, _, _}) when is_list(acc) do
    {:ok, acc, rest}
  end

  defp unwrap({:error, <<first::binary-size(1), reason::binary>>, rest, _, _, offset}),
    do:
      {:error,
       {Cldr.Message.Parser.ParseError,
        "#{String.capitalize(first)}#{reason}. Could not parse the remaining #{inspect(rest)} " <>
          "starting at position #{offset + 1}"}}
end
