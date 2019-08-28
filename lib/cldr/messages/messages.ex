defmodule Cldr.Message do
  @moduledoc """
  Implements the [ICU Message Format](http://userguide.icu-project.org/formatparse/messages)
  with functions to parse and interpolate messages.

  """
  alias Cldr.Message.Parser
  import Kernel, except: [to_string: 1]

  @type message :: binary()
  @type arguments :: list() | map()
  @type options :: Keyword.t()

  @doc false
  def cldr_backend_provider(config) do
    Cldr.Message.Backend.define_message_module(config)
  end

  @doc false
  def configured_message_format(format, backend) do
    Module.concat(backend, Message).message_format(format)
  end

  def format(message, args \\ [], options \\ []) do
    case format_to_list(message, args, options) do
      {:ok, message} -> {:ok, :erlang.iolist_to_binary(message)}
      other -> other
    end
  end

  def format!(message, args \\ [], options \\ []) do
    case format_to_list(message, args, options) do
      {:ok, message} -> :erlang.iolist_to_binary(message)
      {:error, {exception, reason}} -> raise exception, reason
      other -> other
    end
  end

  @doc """
  Formats an ICU message into an iolist

  """
  @spec format(message() | list() | tuple(), arguments(), options()) ::
          list() | {:ok, list()} | {:error, {module(), binary()}}

  def format_to_list(message, args \\ [], options \\ [])

  def format_to_list(message, args, options) when is_binary(message) do
    options =
      default_options()
      |> Keyword.merge(options)

    options =
      if Keyword.has_key?(options, :backend) do
        options
      else
        Keyword.put(options, :backend, Cldr.default_backend())
      end

    case Parser.parse(message) do
      {:ok, result} ->
        {:ok, format_to_list(result, args, options)}

      other ->
        other
    end
  end

  def format_to_list([head], args, options) do
    [format_to_string(format(head, args, options))]
  end

  def format_to_list([head | rest], args, options) do
    [format_to_string(format_to_list(head, args, options)) | format_to_list(rest, args, options)]
  end

  def format_to_list({:literal, literal}, _args, _options) when is_binary(literal) do
    literal
  end

  def format_to_list({:pos_arg, arg}, args, _options) when is_map(args) do
    Map.fetch!(args, String.to_existing_atom(arg))
  end

  def format_to_list({:pos_arg, arg}, args, _options) when is_list(args) do
    Enum.at(args, arg)
  end

  def format_to_list({:named_arg, arg}, args, _options) when is_map(args) do
    Map.fetch!(args, String.to_existing_atom(arg))
  end

  def format_to_list({:named_arg, arg}, args, _options) when is_list(args) do
    Keyword.fetch!(args, String.to_existing_atom(arg))
  end

  def format_to_list(:value, _args, options) do
    Keyword.fetch!(options, :arg)
  end

  def format_to_list({:simple_format, arg, type}, args, options) do
    arg = format(arg, args, options)
    format_to_list({arg, type}, args, options)
  end

  def format_to_list({:simple_format, arg, type, style}, args, options) do
    arg = format(arg, args, options)
    format_to_list({arg, type, style}, args, options)
  end

  def format_to_list({number, :number}, _args, options) do
    Cldr.Number.to_string!(number, options)
  end

  @integer_format "#"
  def format_to_list({number, :number, :integer}, _args, options) do
    options = Keyword.put(options, :format, @integer_format)
    Cldr.Number.to_string!(number, options)
  end

  def format_to_list({number, :number, :short}, _args, options) do
    options = Keyword.put(options, :format, :short)
    Cldr.Number.to_string!(number, options)
  end

  def format_to_list({number, :number, :currency}, _args, options) do
    options = Keyword.put(options, :format, :currency)
    Cldr.Number.to_string!(number, options)
  end

  def format_to_list({number, :number, :percent}, _args, options) do
    options = Keyword.put(options, :format, :percent)
    Cldr.Number.to_string!(number, options)
  end

  def format_to_list({number, :number, :permille}, _args, options) do
    options = Keyword.put(options, :format, :permille)
    Cldr.Number.to_string!(number, options)
  end

  def format_to_list({number, :number, format}, _args, options) when is_binary(format) do
    options = Keyword.put(options, :format, format)
    Cldr.Number.to_string!(number, options)
  end

  def format_to_list({number, :number, format}, _args, options) when is_atom(format) do
    format_options = configured_message_format(format, options[:backend])
    options = Keyword.merge(options, format_options)
    Cldr.Number.to_string!(number, options)
  end

  def format_to_list({number, :spellout}, _args, options) do
    options = Keyword.put(options, :format, :spellout)
    Cldr.Number.to_string!(number, options)
  end

  def format_to_list({number, :spellout, :verbose}, _args, options) do
    options = Keyword.put(options, :format, :spellout_verbose)
    Cldr.Number.to_string!(number, options)
  end

  def format_to_list({number, :spellout, :year}, _args, options) do
    options = Keyword.put(options, :format, :spellout_year)
    Cldr.Number.to_string!(number, options)
  end

  def format_to_list({number, :spellout, :ordinal}, _args, options) do
    options = Keyword.put(options, :format, :spellout_ordinal)
    Cldr.Number.to_string!(number, options)
  end

  def format_to_list({date, :date}, _args, options) do
    Cldr.Date.to_string!(date, options)
  end

  def format_to_list({date, :date, format}, _args, options) when is_binary(format) do
    options = Keyword.put(options, :format, format)
    Cldr.Time.to_string!(date, options)
  end

  def format_to_list({date, :date, format}, _args, options)
      when format in [:short, :medium, :long, :full] do
    options = Keyword.put(options, :format, format)
    Cldr.Date.to_string!(date, options)
  end

  def format_to_list({number, :date, format}, _args, options) when is_atom(format) do
    format_options = configured_message_format(format, options[:backend])
    options = Keyword.merge(options, format_options)
    Cldr.Date.to_string!(number, options)
  end

  def format_to_list({time, :time}, _args, options) do
    Cldr.Time.to_string!(time, options)
  end

  def format_to_list({time, :time, format}, _args, options) when is_binary(format) do
    options = Keyword.put(options, :format, format)
    Cldr.Time.to_string!(time, options)
  end

  def format_to_list({time, :time, format}, _args, options)
      when format in [:short, :medium, :long, :full] do
    options = Keyword.put(options, :format, format)
    Cldr.Time.to_string!(time, options)
  end

  def format_to_list({number, :time, format}, _args, options) when is_atom(format) do
    format_options = configured_message_format(format, options[:backend])
    options = Keyword.merge(options, format_options)
    Cldr.Time.to_string!(number, options)
  end

  def format_to_list({datetime, :datetime}, _args, options) do
    Cldr.DateTime.to_string!(datetime, options)
  end

  def format_to_list({datetime, :datetime, format}, _args, options) when is_binary(format) do
    options = Keyword.put(options, :format, format)
    Cldr.DateTime.to_string!(datetime, options)
  end

  def format_to_list({datetime, :datetime, format}, _args, options)
      when format in [:short, :medium, :long, :full] do
    options = Keyword.put(options, :format, format)
    Cldr.DateTime.to_string!(datetime, options)
  end

  def format_to_list({number, :datetime, format}, _args, options) when is_atom(format) do
    format_options = configured_message_format(format, options[:backend])
    options = Keyword.merge(options, format_options)
    Cldr.DateTime.to_string!(number, options)
  end

  def format_to_list({money, :money, format}, _args, options) when format in [:short, :long] do
    options = Keyword.put(options, :format, format)
    Money.to_string!(money, options)
  end

  def format_to_list({number, :money, format}, _args, options) when is_atom(format) do
    format_options = configured_message_format(format, options[:backend])
    options = Keyword.merge(options, format_options)
    Money.to_string!(number, options)
  end

  def format_to_list({list, :list}, _args, options) do
    Cldr.List.to_string!(list, options)
  end

  def format_to_list({list, :list, :and}, _args, options) do
    Cldr.List.to_string!(list, options)
  end

  @list_styles Cldr.List.known_list_styles()

  def format_to_list({list, :list, format}, _args, options) when format in @list_styles do
    options = Keyword.put(options, :format, format)
    Cldr.List.to_string!(list, options)
  end

  def format_to_list({number, :list, format}, _args, options) when is_atom(format) do
    format_options = configured_message_format(format, options[:backend])
    options = Keyword.merge(options, format_options)
    Cldr.List.to_string!(number, options)
  end

  def format_to_list({unit, :unit}, _args, options) do
    Cldr.Unit.to_string!(unit, options)
  end

  def format_to_list({unit, :unit, format}, _args, options)
      when format in [:long, :short, :narrow] do
    options = Keyword.put(options, :format, format)
    Cldr.Unit.to_string!(unit, options)
  end

  def format_to_list({number, :unit, format}, _args, options) when is_atom(format) do
    format_options = configured_message_format(format, options[:backend])
    options = Keyword.merge(options, format_options)
    Cldr.Unit.to_string!(number, options)
  end

  def format_to_list({:select, arg, selections}, args, options) when is_map(selections) do
    arg =
      arg
      |> format!(args, options)
      |> to_maybe_integer

    message = Map.get(selections, arg) || other(selections, arg)
    format(message, args, options)
  end

  def format_to_list({:plural, arg, {:offset, offset}, plurals}, args, options)
      when is_map(plurals) do
    format_plural(arg, Cardinal, offset, plurals, args, options)
  end

  def format_to_list({:select_ordinal, arg, plurals}, args, options) when is_map(plurals) do
    format_plural(arg, Ordinal, 0, plurals, args, options)
  end

  defp format_to_string(value) when is_number(value) do
    Cldr.Number.to_string!(value)
  end

  defp format_to_string(%Decimal{} = value) do
    Cldr.Number.to_string!(value)
  end

  defp format_to_string(%Date{} = value) do
    Cldr.Date.to_string!(value)
  end

  defp format_to_string(%Time{} = value) do
    Cldr.Time.to_string!(value)
  end

  defp format_to_string(%DateTime{} = value) do
    Cldr.DateTime.to_string!(value)
  end

  defp format_to_string(value) do
    Kernel.to_string(value)
  end

  defp format_plural(arg, type, offset, plurals, args, options) do
    arg =
      arg
      |> format!(args, options)
      |> to_maybe_integer

    formatted_arg = Cldr.Number.to_string!(arg - offset, options)

    options =
      options
      |> Keyword.put(:type, type)
      |> Keyword.put(:arg, formatted_arg)

    plural_type = Cldr.Number.PluralRule.plural_type(arg - offset, options)
    message = Map.get(plurals, arg) || Map.get(plurals, plural_type) || other(plurals, arg)
    format(message, args, options)
  end

  @doc false
  def default_options do
    [locale: Cldr.get_locale()]
  end

  @spec other(map(), any()) :: any()
  defp other(map, _arg) when is_map(map) do
    Map.fetch!(map, "other")
  end

  @spec to_maybe_integer(number | Decimal.t() | String.t() | list()) ::
          number() | String.t() | atom()
  defp to_maybe_integer(arg) when is_integer(arg) do
    arg
  end

  defp to_maybe_integer(arg) when is_float(arg) do
    trunc(arg)
  end

  defp to_maybe_integer(%Decimal{} = arg) do
    Decimal.to_integer(arg)
  end

  defp to_maybe_integer(other) do
    other
  end
end
