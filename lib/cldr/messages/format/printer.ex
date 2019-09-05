defmodule Cldr.Message.Print do
  @moduledoc false

  @doc """
  Takes a message AST and converts it back into a string.

  There are two purposes for this:

  1. To define a canonical string form of a message that can be used as a translation key
  2. To pretty print it for use in translation workbenches
  """
  import Kernel, except: [to_string: 1]

  def to_string(message, options \\ [])

  def to_string(message, options) when is_list(options) do
    options = Map.new(options)
    message
    |> to_string(options)
    |> :erlang.iolist_to_binary
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

  def to_string({:plural, arg, {:offset, 0}, choices}, options) do
    [_, arg, _] = to_string(arg, options)
    [?{, arg, ", ", "plural", ", ", to_string(choices, options), ?}]
  end

  def to_string({:plural, arg, {:offset, offset}, choices}, options) do
    [_, arg, _] = to_string(arg, options)
    [?{, arg, ", ", "plural", ", ", "offset: ", Kernel.to_string(offset), ?\s,
      to_string(choices, options), ?}]
  end

  def to_string({:select, arg, choices}, options) do
    [_, arg, _] = to_string(arg, options)
    [?{, arg, ", ", "select", ", ", to_string(choices, options), ?}]
  end

  def to_string({:selectordinal, arg, choices}, options) do
    [_, arg, _] = to_string(arg, options)
    [?{, arg, ", ", "selectordinal", ", ", to_string(choices, options), ?}]
  end

  def to_string(%{} = choices, options) do
    Enum.map(choices, fn
      {choice, value} when is_integer(choice) ->
        [?=, Kernel.to_string(choice), ?{, to_string(value, options), ?}]
      {choice, value} ->
        [Kernel.to_string(choice), ?{, to_string(value, options), ?}]
    end)
    |> Enum.intersperse(?\s)
  end
end