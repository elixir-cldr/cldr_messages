defmodule Cldr.Message.Parser.Combinator do
  @moduledoc false

  import NimbleParsec

  def message do
    optional(message_text())
    |> repeat(argument() |> concat(message_text()))
    |> label("a CLDR message")
  end

  def message_text do
    literal()
    |> repeat()
  end

  def plural_message do
    optional(plural_message_text())
    |> repeat(argument() |> concat(plural_message_text()))
    |> label("a CLDR plural message")
  end

  def plural_message_text do
    choice(empty(), [plural_literal(), arg_value()])
    |> repeat()
  end

  def literal do
    choice(empty(), [
      escaped_char(),
      utf8_string([{:not, ?{}, {:not, ?}}], min: 1)
    ])
    |> reduce(:literal)
  end

  def plural_literal do
    choice(empty(), [
      escaped_char(),
      utf8_string([{:not, ?{}, {:not, ?}}, {:not, ?#}], min: 1)
    ])
    |> reduce(:literal)
  end

  def literal(args) do
    {:literal, List.to_string(args)}
  end

  def arg_value do
    utf8_char([?#])
    |> reduce(:value)
  end

  def value(_) do
    :value
  end

  def escaped_char do
    choice([
      string("'{") |> replace("{"),
      string("'}") |> replace("}"),
      string("'#") |> replace("#"),
      string("''") |> replace("'")
    ])
  end

  def whitespace do
    repeat(empty(), ascii_char([?\s, ?\t, ?\n]))
  end

  def left_brace do
    ignore(optional(whitespace()))
    |> ignore(utf8_char([?{]))
  end

  def right_brace do
    ignore(optional(whitespace()))
    |> ignore(utf8_char([?}]))
  end

  def comma do
    ignore(optional(whitespace()))
    |> ignore(utf8_char([?,]))
    |> ignore(optional(whitespace()))
  end

  # argument = noneArg | simpleArg | complexArg
  def argument do
    choice(empty(), [
      none_argument(),
      simple_format(),
      complex_argument()
    ])
  end

  # noneArg = '{' argNameOrNumber '}'
  def none_argument do
    left_brace()
    |> concat(arg_name_or_number())
    |> concat(right_brace())
  end

  # simpleArg = '{' argNameOrNumber ',' argType [',' argStyle] '}'
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
  def complex_argument do
    choice(empty(), [
      plural_argument(),
      select_argument(),
      select_ordinal_argument()
    ])
  end

  # pluralArg = '{' argNameOrNumber ',' "plural" ',' pluralStyle '}'
  def plural_argument do
    left_brace()
    |> concat(arg_name_or_number())
    |> concat(comma())
    |> ignore(argument("plural"))
    |> concat(plural_style())
    |> concat(right_brace())
    |> reduce(:plural_select)
  end

  def plural_select([arg, plural_args, selects]) do
    {:plural, arg, plural_args, selects}
  end

  # selectArg = '{' argNameOrNumber ',' "select" ',' selectStyle '}'
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
  def select_ordinal_argument do
    left_brace()
    |> concat(arg_name_or_number())
    |> concat(comma())
    |> ignore(argument("selectordinal"))
    |> concat(plural_style())
    |> concat(right_brace())
    |> reduce(:select_ordinal)
  end

  def select_ordinal([arg, plural_args, selects]) do
    {:select_ordinal, arg, plural_args, selects}
  end

  def argument(type) do
    ignore(optional(whitespace()))
    |> string(type)
    |> ignore(optional(whitespace()))
  end

  # selectStyle = (selector '{' message '}')+
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
  def plural_style do
    optional(plural_arguments())
    |> optional(comma())
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

  defp parse(parser) do
    parsec(parser)
  end

  def offset([_, offset]) do
    {:offset, offset}
  end

  def plural_type([_, type]) do
    {:plural_type, type}
  end

  def list_to_map(list) do
    map = Map.new(list, fn [key | value] -> {key, value} end)

    if Map.has_key?(map, :other) or Map.has_key?(map, "other") do
      map
    else
      raise Cldr.Message.ParseError,
            "'plural', 'select' and 'selectordinal' arguments must have an 'other' clause. Found #{inspect(map)}"
    end
  end

  def plural_arguments do
    one_plural_argument()
    |> repeat
    |> reduce(:resolve_plural_arguments)
  end

  def one_plural_argument do
    comma()
    |> choice([
      offset_value() |> reduce(:offset),
      plural_type_value() |> reduce(:plural_type)
    ])
  end

  def resolve_plural_arguments(args) do
    Keyword.new(args)
  end

  # offsetValue = "offset:" number
  def offset_value do
    ignore(optional(whitespace()))
    |> string("offset:")
    |> ignore(optional(whitespace()))
    |> integer(min: 1)
  end

  # pluralType = "type:" [ordinal, cardinal, short]
  def plural_type_value do
    ignore(optional(whitespace()))
    |> string("type:")
    |> ignore(optional(whitespace()))
    |> choice([string("cardinal"), string("ordinal"), string("short")])
    |> reduce(:capitalize_type)
  end

  def capitalize_type(args) do
    IO.inspect(args)
  end

  # selector = explicitValue | keyword
  def plural_selector do
    ignore(optional(whitespace()))
    |> choice([explicit_value(), keyword()])
    |> ignore(optional(whitespace()))
  end

  # selector = arg_name
  def choice_selector do
    ignore(optional(whitespace()))
    |> concat(selector())
    |> ignore(optional(whitespace()))
  end

  # explicitValue = '=' number  // adjacent, no white space in between
  def explicit_value do
    ignore(string("="))
    |> integer(min: 1)
  end

  # keyword =zero | one | two | few | many | other
  def keyword do
    choice(empty(), [
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

  def arg_name_or_number do
    ignore(optional(whitespace()))
    |> choice([arg_number(), arg_name()])
    |> ignore(optional(whitespace()))
  end

  def arg_number do
    integer(min: 1)
    |> reduce(:pos_arg)
  end

  def pos_arg([arg]) do
    {:pos_arg, arg}
  end

  def arg_name do
    utf8_string([?a..?z, ?A..?Z, ?0..?9, ?_], min: 1)
    |> reduce(:named_arg)
  end

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
  def arg_style do
    ignore(optional(whitespace()))
    |> choice([
      # For numbers
      string("integer") |> reduce(:to_atom),
      string("currency") |> reduce(:to_atom),
      string("percent") |> reduce(:to_atom),
      string("permille") |> reduce(:to_atom),
      string("verbose") |> reduce(:to_atom),
      string("year") |> reduce(:to_atom),
      string("ordinal") |> reduce(:to_atom),

      # For units, dates, times, ...
      string("short") |> reduce(:to_atom),
      string("medium") |> reduce(:to_atom),
      string("long") |> reduce(:to_atom),
      string("full") |> reduce(:to_atom),

      # For lists
      string("or_narrow") |> reduce(:to_atom),
      string("or_short") |> reduce(:to_atom),
      string("or") |> reduce(:to_atom),
      string("standard_narrow") |> reduce(:to_atom),
      string("standard_short") |> reduce(:to_atom),
      string("standard") |> reduce(:to_atom),

      # For units
      string("unit_narrow") |> reduce(:to_atom),
      string("unit_short") |> reduce(:to_atom),
      string("unit") |> reduce(:to_atom),

      # Everything else
      arg_format()
    ])
    |> ignore(optional(whitespace()))
  end

  def arg_format do
    choice([atom_arg(), string_arg()])
  end

  def atom_arg do
    ignore(ascii_char([?:]))
    |> repeat(ascii_char([?a..?z, ?A..?Z, ?0..?9, ?_]))
    |> reduce({List, :to_atom, []})
  end

  def string_arg do
    ignore(optional(string("::")))
    |> choice([
      escaped_char(),
      utf8_char([{:not, ?}}, {:not, ?\n}])
    ])
    |> repeat
    |> reduce({List, :to_string, []})
  end

  def to_atom([string]) do
    String.to_atom(string)
  end
end
