defmodule Cldr.Message.Print do
  @moduledoc false

  @doc """
  Takes a message AST and converts it back into a string.

  There are two purposes for this:

  1. To define a canonical string form of a message that can be used as a translation key
  2. To pretty print it for use in translation workbenches

  ## Arguments

  * `message` is a message AST returned by
    `Cldr.Message.Parser.parse/1`

  * `options` is a keyword list of options. The
    default is `[]`

  ## Options

  * `:pretty` determines if the message if
    formatted with indentation to aid readability.
    The default is `false`.

  ## Returns

  * The message AST formatted as a string

  ## Examples

  """
  import Kernel, except: [to_string: 1]

  def to_string(message, options \\ [])

  def to_string(message, options) when is_list(options) do
    options =
      default_options()
      |> Keyword.merge(options)
      |> Map.new()

    message
    |> to_string(options)
    |> :erlang.iolist_to_binary()
  end

  def to_string([head | []], %{} = options) do
    to_string(head, options)
  end

  def to_string([head | rest], %{} = options) do
    [to_string(head, options), to_string(rest, options)]
  end

  def to_string({:named_arg, arg}, _options) do
    [?{, arg, ?}]
  end

  def to_string({:named_arg, format, arg}, _options) do
    [?{, arg, ", ", format, ?}]
  end

  def to_string({:named_arg, format, style, arg}, _options) do
    [?{, arg, ", ", format, ", ", style, ?}]
  end

  def to_string({:pos_arg, arg}, _options) do
    [?{, Kernel.to_string(arg), ?}]
  end

  def to_string({:pos_arg, format, arg}, _options) do
    [?{, Kernel.to_string(arg), ", ", format, ?}]
  end

  def to_string({:pos_arg, format, style, arg}, _options) do
    [?{, Kernel.to_string(arg), ", ", format, ", ", style, ?}]
  end

  def to_string({:literal, literal}, _options), do: literal

  def to_string(:value, _options), do: "#"

  def to_string({:simple_format, var, format, style}, options) do
    [_, var, _] = to_string(var, options)
    [?{, var, ", ", Kernel.to_string(format), ", ", Kernel.to_string(style), ?}]
  end

  def to_string({:plural, arg, [], choices}, %{pretty: true, level: 0} = options) do
    [_, arg, _] = to_string(arg, options)
    [?{, arg, ", ", "plural", ",", to_string(choices, increment_level(options)), ?}]
  end

  def to_string({:plural, arg, [], choices}, %{pretty: true, level: level} = options) do
    [_, arg, _] = to_string(arg, options)
    [?\n, pad(level), ?{, arg, "plural", ",", to_string(choices, increment_level(options)), ?}]
  end

  def to_string({:plural, arg, [], choices}, options) do
    [_, arg, _] = to_string(arg, options)
    [?{, arg, ", ", "plural", ", ", to_string(choices, options), ?}]
  end

  def to_string({:plural, arg, plural_args, choices}, %{pretty: true, level: 0} = options) do
    [_, arg, _] = to_string(arg, options)

    [
      ?{,
      arg,
      ", ",
      "plural",
      ", ",
      format_plural_args(plural_args),
      to_string(choices, increment_level(options)),
      ?}
    ]
  end

  def to_string(
        {:plural, arg, plural_args, choices},
        %{pretty: true, level: level} = options
      ) do
    [_, arg, _] = to_string(arg, options)

    [
      ?\n,
      pad(level),
      ?{,
      arg,
      ", ",
      "plural",
      ", ",
      format_plural_args(plural_args),
      to_string(choices, increment_level(options)),
      ?}
    ]
  end

  def to_string({:plural, arg, plural_args, choices}, options) do
    [_, arg, _] = to_string(arg, options)

    [
      ?{,
      arg,
      ", ",
      "plural",
      ", ",
      format_plural_args(plural_args),
      ?\s,
      to_string(choices, options),
      ?}
    ]
  end

  def to_string({:select, arg, choices}, %{pretty: true, level: 0} = options) do
    [_, arg, _] = to_string(arg, options)
    [?{, arg, ", ", "select", ?,, to_string(choices, increment_level(options)), ?}]
  end

  def to_string({:select, arg, choices}, %{pretty: true, level: level} = options) do
    [_, arg, _] = to_string(arg, options)

    [
      ?\n,
      pad(level),
      ?{,
      arg,
      ", ",
      "select",
      ", ",
      to_string(choices, increment_level(options)),
      ?}
    ]
  end

  def to_string({:select, arg, choices}, options) do
    [_, arg, _] = to_string(arg, options)
    [?{, arg, ", ", "select", ", ", to_string(choices, options), ?}]
  end

  def to_string({:select_ordinal, arg, [], choices}, %{pretty: true, level: 0} = options) do
    [_, arg, _] = to_string(arg, options)
    [?{, arg, ", ", "selectordinal", ?,, to_string(choices, increment_level(options)), ?}]
  end

  def to_string({:select_ordinal, arg, [], choices}, %{pretty: true, level: level} = options) do
    [_, arg, _] = to_string(arg, options)

    [
      ?\n,
      pad(level),
      ?{,
      arg,
      ", ",
      "selectordinal",
      ?,,
      to_string(choices, increment_level(options)),
      ?}
    ]
  end

  def to_string({:select_ordinal, arg, [], choices}, options) do
    [_, arg, _] = to_string(arg, options)
    [?{, arg, ", ", "selectordinal", ", ", to_string(choices, options), ?}]
  end

  def to_string(%{} = choices, %{pretty: true, level: level} = options) do
    next_level_options = %{options | level: level + 1, nested: true}

    choices
    |> Enum.sort(&choice_sorter/2)
    |> Enum.map(fn
      {choice, value} when is_integer(choice) ->
        [
          ?\n,
          pad(level),
          ?=,
          Kernel.to_string(choice),
          ?\s,
          ?{,
          to_string(value, next_level_options),
          ?}
        ]

      {choice, value} ->
        [
          ?\n,
          pad(level),
          Kernel.to_string(choice),
          ?\s,
          ?{,
          to_string(value, next_level_options),
          ?}
        ]
    end)
  end

  def to_string(%{} = choices, options) do
    choices
    |> Enum.sort(&choice_sorter/2)
    |> Enum.map(fn
      {choice, value} when is_integer(choice) ->
        [?=, Kernel.to_string(choice), ?\s, ?{, to_string(value, options), ?}]

      {choice, value} ->
        [Kernel.to_string(choice), ?\s, ?{, to_string(value, options), ?}]
    end)
    |> Enum.intersperse(?\s)
  end

  defp format_plural_args(args) do
    Enum.map(args, &format_plural_arg/1)
  end

  defp format_plural_arg({:offset, offset}), do: ["offset: ", Kernel.to_string(offset)]
  defp format_plural_arg({:type, type}), do: ["type: ", type]

  defp default_options do
    [pretty: false, level: 0, nested: false]
  end

  def increment_level(%{level: level} = options, inc \\ 1) do
    %{options | level: level + inc}
  end

  # Use Erlang term ordering to put integers before atoms
  def choice_sorter({:one, _}, {b, _}) when is_atom(b), do: true
  def choice_sorter({a, _}, {:one, _}) when is_atom(a), do: false

  def choice_sorter({a, _}, {:few, _}) when a in [:one, :two], do: true
  def choice_sorter({:few, _}, {b, _}) when b in [:one, :two], do: false

  def choice_sorter({a, _}, {:many, _}) when a in [:one, :two, :few], do: true
  def choice_sorter({:many, _}, {b, _}) when b in [:one, :two, :few], do: false

  # :other sorts last
  def choice_sorter({:other, _}, {_b, _}), do: false

  # All others use term ordering
  def choice_sorter({a, _}, {b, _}), do: a <= b

  def pad(0), do: ""
  def pad(1), do: "  "
  def pad(2), do: "    "
  def pad(3), do: "      "
  def pad(4), do: "        "
  def pad(5), do: "          "
end
