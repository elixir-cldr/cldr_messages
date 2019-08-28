defmodule Cldr.Message.Parser.Combinator do
  @moduledoc false

  import NimbleParsec

  @spec message :: NimbleParsec.t()
  def message do
    optional(message_text())
    |> repeat(argument() |> concat(message_text()))

    # |> label("a CLDR message")
  end

  @spec message_text :: NimbleParsec.t()
  def message_text do
    literal()
    |> repeat()
    |> optional()
  end

  @spec plural_message :: NimbleParsec.t()
  def plural_message do
    optional(plural_message_text())
    |> repeat(argument() |> concat(plural_message_text()))

    # |> label("a CLDR plural message")
  end

  @spec plural_message_text :: NimbleParsec.t()
  def plural_message_text do
    choice([plural_literal(), arg_value()])
    |> repeat()
  end

  @spec literal :: NimbleParsec.t()
  def literal do
    choice([
      reduce(string("'{"), :escaped_char),
      reduce(string("'}"), :escaped_char),
      utf8_string([{:not, ?{}, {:not, ?}}], min: 1)
    ])
    |> reduce(:literal)
  end

  @spec plural_literal :: NimbleParsec.t()
  def plural_literal do
    choice([
      reduce(string("'{"), :escaped_char),
      reduce(string("'}"), :escaped_char),
      reduce(string("'#"), :escaped_char),
      reduce(string("''"), :escaped_char),
      utf8_string([{:not, ?{}, {:not, ?}}, {:not, ?#}], min: 1)
    ])
    |> reduce(:literal)
  end

  def literal(args) do
    {:literal, List.to_string(args)}
  end

  @spec arg_value :: NimbleParsec.t()
  def arg_value do
    utf8_char([?#])
    |> reduce(:value)
  end

  def value(_) do
    :value
  end

  def escaped_char(["'{"]), do: "{"
  def escaped_char(["'}"]), do: "}"
  def escaped_char(["'#"]), do: "#"
  def escaped_char(["''"]), do: "'"

  @spec whitespace :: NimbleParsec.t()
  def whitespace do
    repeat(ascii_char([?\s, ?\t, ?\n]))
  end

  @spec left_brace :: NimbleParsec.t()
  def left_brace do
    ignore(optional(whitespace()))
    |> ignore(utf8_char([?{]))
  end

  @spec right_brace :: NimbleParsec.t()
  def right_brace do
    ignore(optional(whitespace()))
    |> ignore(utf8_char([?}]))
  end

  @spec comma :: NimbleParsec.t()
  def comma do
    ignore(utf8_char([?,]))
  end

  # argument = noneArg | simpleArg | complexArg
  @spec argument :: NimbleParsec.t()
  def argument do
    choice([
      none_argument(),
      simple_format(),
      complex_argument()
    ])
  end

  # noneArg = '{' argNameOrNumber '}'
  @spec none_argument :: NimbleParsec.t()
  def none_argument do
    left_brace()
    |> concat(arg_name_or_number())
    |> concat(right_brace())
  end

  # simpleArg = '{' argNameOrNumber ',' argType [',' argStyle] '}'
  @spec simple_format :: NimbleParsec.t()
  def simple_format do
    left_brace()
    |> concat(arg_name_or_number())
    |> concat(comma())
    |> concat(arg_type())
    |> optional(comma() |> concat(arg_style()))
    |> concat(right_brace())
    |> reduce(:simple_format)
  end

  def simple_format([arg, type]) do
    {:simple_format, arg, type}
  end

  def simple_format([arg, type, style]) do
    {:simple_format, arg, type, style}
  end

  # complexArg = choiceArg | pluralArg | selectArg | selectordinalArg
  @spec complex_argument :: NimbleParsec.t()
  def complex_argument do
    choice([
      plural_argument(),
      select_argument(),
      select_ordinal_argument()
    ])
  end

  # pluralArg = '{' argNameOrNumber ',' "plural" ',' pluralStyle '}'
  @spec plural_argument :: NimbleParsec.t()
  def plural_argument do
    left_brace()
    |> concat(arg_name_or_number())
    |> concat(comma())
    |> ignore(argument("plural"))
    |> concat(comma())
    |> concat(plural_style())
    |> concat(right_brace())
    |> reduce(:plural_select)
  end

  def plural_select([arg, offset, selects]) do
    {:plural, arg, offset, selects}
  end

  def plural_select([arg, selects]) do
    {:plural, arg, {:offset, 0}, selects}
  end

  # selectArg = '{' argNameOrNumber ',' "select" ',' selectStyle '}'
  @spec select_argument :: NimbleParsec.t()
  def select_argument do
    left_brace()
    |> concat(arg_name_or_number())
    |> concat(comma())
    |> ignore(argument("select"))
    |> concat(comma())
    |> concat(select_style())
    |> concat(right_brace())
    |> reduce(:select)
  end

  def select([arg, selects]) do
    {:select, arg, selects}
  end

  # selectordinalArg = '{' argNameOrNumber ',' "selectordinal" ',' pluralStyle '}'
  @spec select_ordinal_argument :: NimbleParsec.t()
  def select_ordinal_argument do
    left_brace()
    |> concat(arg_name_or_number())
    |> concat(comma())
    |> ignore(argument("selectordinal"))
    |> concat(comma())
    |> concat(plural_style())
    |> concat(right_brace())
    |> reduce(:select_ordinal)
  end

  def select_ordinal([arg, selects]) do
    {:select_ordinal, arg, selects}
  end

  def argument(type) do
    ignore(optional(whitespace()))
    |> string(type)
    |> ignore(optional(whitespace()))
  end

  # selectStyle = (selector '{' message '}')+
  @spec select_style :: NimbleParsec.t()
  def select_style do
    times(
      wrap(
        choice_selector()
        |> concat(left_brace())
        |> concat(parse(:message))
        |> concat(right_brace())
      ),
      min: 1
    )
    |> reduce(:list_to_map)
  end

  # pluralStyle = [offsetValue] (selector '{' message '}')+
  @spec plural_style :: NimbleParsec.t()
  def plural_style do
    optional(offset_value() |> reduce(:offset))
    |> reduce(
      times(
        wrap(
          plural_selector()
          |> concat(left_brace())
          |> concat(parse(:plural_message))
          |> concat(right_brace())
        ),
        min: 1
      ),
      :list_to_map
    )
  end

  @spec parse(atom()) :: NimbleParsec.t()
  defp parse(parser) do
    parsec(parser)
  end

  def offset([_, offset]) do
    {:offset, offset}
  end

  def list_to_map(list) do
    map = Map.new(list, fn [key | value] -> {key, value} end)

    if Map.has_key?(map, :other) or Map.has_key?(map, "other") do
      map
    else
      raise Cldr.Message.ParseError,
            "'plural', 'select' and 'selectordinal' arguments must have an 'other' clause. Found #{
              inspect(map)
            }"
    end
  end

  # offsetValue = "offset:" number
  @spec offset_value :: NimbleParsec.t()
  def offset_value do
    ignore(optional(whitespace()))
    |> string("offset:")
    |> ignore(optional(whitespace()))
    |> integer(min: 1)
  end

  # selector = explicitValue | keyword
  @spec plural_selector :: NimbleParsec.t()
  def plural_selector do
    ignore(optional(whitespace()))
    |> choice([explicit_value(), keyword()])
    |> ignore(optional(whitespace()))
  end

  # selector = arg_name
  @spec choice_selector :: NimbleParsec.t()
  def choice_selector do
    ignore(optional(whitespace()))
    |> concat(selector())
    |> ignore(optional(whitespace()))
  end

  # explicitValue = '=' number  // adjacent, no white space in between
  @spec explicit_value :: NimbleParsec.t()
  def explicit_value do
    ignore(string("="))
    |> integer(min: 1)
  end

  # keyword =zero | one | two | few | many | other
  @spec keyword :: NimbleParsec.t()
  def keyword do
    choice([
      string("zero"),
      string("one"),
      string("two"),
      string("few"),
      string("many"),
      string("other")
    ])
    |> reduce(:atomize)
  end

  def atomize([arg]) do
    String.to_existing_atom(arg)
  end

  @spec arg_name_or_number :: NimbleParsec.t()
  def arg_name_or_number do
    ignore(optional(whitespace()))
    |> choice([arg_number(), arg_name()])
    |> ignore(optional(whitespace()))
  end

  @spec arg_number :: NimbleParsec.t()
  def arg_number do
    integer(min: 1)
    |> reduce(:pos_arg)
  end

  def pos_arg([arg]) do
    {:pos_arg, arg}
  end

  @spec arg_name :: NimbleParsec.t()
  def arg_name do
    utf8_string([?a..?z, ?A..?Z, ?0..?9, ?_], min: 1)
    |> reduce(:named_arg)
  end

  @spec selector :: NimbleParsec.t()
  def selector do
    optional(utf8_char([?:]))
    |> utf8_string([{:not, ?\s}, {:not, ?\n}, {:not, ?\t}, {:not, ?{}], min: 1)
  end

  def named_arg([?:, arg]) do
    {:named_arg, String.to_atom(arg)}
  end

  def named_arg([arg]) do
    {:named_arg, arg}
  end

  # argType = "number" | "date" | "time" | "spellout" | "ordinal" | "duration"
  # Adding "unit", "list" and "money" to the standard
  @spec arg_type :: NimbleParsec.t()
  def arg_type do
    ignore(optional(whitespace()))
    |> choice([
      string("number"),
      string("datetime"),
      string("date"),
      string("time"),
      string("spellout"),
      string("ordinal"),
      string("unit"),
      string("list"),
      string("money")
    ])
    |> ignore(optional(whitespace()))
    |> reduce(:to_atom)
  end

  # argStyle = "short" | "medium" | "long" | "full" | "integer" | "currency" | "percent" | argStyleText | "::" argSkeletonText
  @spec arg_style :: NimbleParsec.t()
  def arg_style do
    ignore(optional(whitespace()))
    |> choice([
      string("integer") |> reduce(:to_atom),
      string("currency") |> reduce(:to_atom),
      string("percent") |> reduce(:to_atom),
      string("permille") |> reduce(:to_atom),
      string("short") |> reduce(:to_atom),
      string("medium") |> reduce(:to_atom),
      string("long") |> reduce(:to_atom),
      string("full") |> reduce(:to_atom),
      string("verbose") |> reduce(:to_atom),
      string("year") |> reduce(:to_atom),
      string("ordinal") |> reduce(:to_atom),
      string("or_narrow") |> reduce(:to_atom),
      string("or_short") |> reduce(:to_atom),
      string("or") |> reduce(:to_atom),
      string("standard_narrow") |> reduce(:to_atom),
      string("standard_short") |> reduce(:to_atom),
      string("standard") |> reduce(:to_atom),
      string("unit_narrow") |> reduce(:to_atom),
      string("unit_short") |> reduce(:to_atom),
      string("unit") |> reduce(:to_atom),
      arg_format()
    ])
    |> ignore(optional(whitespace()))
  end

  @spec arg_format :: NimbleParsec.t()
  def arg_format do
    choice([atom_arg(), string_arg()])
  end

  def atom_arg do
    ignore(ascii_char([?:]))
    |> repeat(ascii_char([?a..?z, ?A..?Z, ?0..?9, ?_]))
    |> reduce({List, :to_existing_atom, []})
  end

  def string_arg do
    choice([
      string("'}") |> reduce(:escaped_char),
      utf8_char([{:not, ?}}, {:not, ?\n}])
    ])
    |> repeat
    |> reduce({List, :to_string, []})
  end

  def to_atom([string]) do
    String.to_existing_atom(string)
  end
end
