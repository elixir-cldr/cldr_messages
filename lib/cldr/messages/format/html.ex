defmodule Cldr.Message.HTML do
  @moduledoc false

  @doc """
  Takes a message AST and converts it back into
  HTML.

  """
  def to_html(message, options \\ [])

  def to_html(message, options) when is_list(options) do
    options =
      default_options()
      |> Keyword.merge(options)
      |> Map.new

    message
    |> to_html(options)
    |> wrap_tag(:code)
    |> List.insert_at(0, css())
    |> :erlang.iolist_to_binary
  end

  def to_html([head | []], %{} = options) do
    to_html(head, options)
  end

  def to_html([head | rest], %{} = options) do
    [to_html(head, options), to_html(rest, options)]
  end

  def to_html({arg_type, arg}, _options) when arg_type in [:named_arg, :pos_arg] do
    [lbrace(), arg(arg), rbrace()]
  end

  def to_html({arg_type, format, arg}, _options) when arg_type in [:named_arg, :pos_arg] do
    [lbrace(), arg(arg), syntax(","), literal(?\s), format(format), rbrace()]
  end

  def to_html({arg_type, format, style, arg}, _options) when arg_type in [:named_arg, :pos_arg] do
    [lbrace(), arg(arg), syntax(","), literal(?\s), format(format), syntax(","), literal(?\s), style(style), rbrace()]
  end

  def to_html({:literal, literal}, _options), do: literal(literal)

  def to_html(:value, _options), do: syntax("#")

  def to_html({:simple_format, var, format, style}, options) do
    [_, var, _] = to_html(var, options)
    [lbrace(), var, syntax(","), literal(?\s), format(format), syntax(","), literal(?\s),
      style(style), rbrace()]
  end

  def to_html({:plural, arg, {:offset, 0}, choices}, options) do
    [_, arg, _] = to_html(arg, options)
    [lbrace(), arg, syntax(","), literal(?\s), keyword("plural"), syntax(","), literal(?\s),
      to_html(choices, options), rbrace()]
    |> wrap_tag(:div, class: :plural)
  end

  def to_html({:plural, arg, {:offset, offset}, choices}, options) do
    [_, arg, _] = to_html(arg, options)
    [lbrace(), arg, syntax(","), literal(?\s), keyword("plural"), syntax(","), literal(?\s),
      keyword("offset"), syntax(":"), literal(?\s), offset(offset), literal(?\s),
      to_html(choices, options), rbrace()]
      |> wrap_tag(:div, class: :plural)
  end

  def to_html({:select, arg, choices}, options) do
    [_, arg, _] = to_html(arg, options)
    [lbrace(), arg, syntax(","), literal(?\s), keyword("select"), syntax(","), literal(?\s),
      to_html(choices, options), rbrace()]
    |> wrap_tag(:div, class: :select)
  end

  def to_html({:selectordinal, arg, choices}, options) do
    [_, arg, _] = to_html(arg, options)
    [lbrace(), arg, syntax(","), literal(?\s), keyword("selectordinal"), syntax(","), literal(?\s),
      to_html(choices, options), rbrace()]
    |> wrap_tag(:div, class: :selectordinal)
  end

  def to_html(%{} = choices, options) do
    Enum.map(choices, fn
      {choice, value} when is_integer(choice) ->
        [selector("=" <> to_string(choice)), literal(?\s), lbrace(),
          to_html(value, options), rbrace()]
        |> wrap_tag(:div, class: :selection)
      {choice, value} ->
        [selector(to_string(choice)), literal(?\s), lbrace(),
          to_html(value, options), rbrace()]
        |> wrap_tag(:div, class: :selection)
    end)
  end

  #
  # Format helpers
  #

  def literal(?\s) do
    "&nbsp"
  end

  def literal(literal) do
    tag(:span, literal, class: :literal)
  end

  def lbrace do
    syntax("{")
  end

  def rbrace do
    syntax("}")
  end

  def arg(arg) do
    tag(:span, arg, class: :arg)
  end

  def keyword(keyword) do
    tag(:span, keyword, class: :keyword)
  end

  def selector(selector) do
    tag(:span, selector, class: :selector)
  end

  def format(format) do
    tag(:span, to_string(format), class: :format)
  end

  def style(style) do
    tag(:span, to_string(style), class: :style)
  end

  def offset(offset) do
    tag(:span, to_string(offset), class: :offset)
  end

  def syntax(char) do
    tag(:span, char, class: :syntax)
  end

  def wrap_tag(content, tag) do
    ["<", to_string(tag), ">", content, "</", to_string(tag), ">"]
  end

  def wrap_tag(content, tag, options) do
    ["<", to_string(tag), " class='", to_string(options[:class]), "'>",
      content, "</", to_string(tag), ">"]
  end

  def tag(tag, content, options) do
    "<" <> to_string(tag) <> " class='" <> to_string(options[:class]) <> "'>" <> content <>
    "</" <> to_string(tag) <> ">"
  end

  defp default_options do
    []
  end

  def css do
    """
    .selection {
      margin-left: 2em;
    }

    .selection > .plural {
      margin-left: 2em;
    }

    .selection > .select {
      margin-left: 2em;
    }

    .selection > .selectordinal {
      margin-left: 2em;
    }
    """
    |> wrap_tag(:style)
  end
end