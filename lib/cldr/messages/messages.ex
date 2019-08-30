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

  @spec format(String.t(), arguments(), options()) ::
    {:ok, String.t()} | {:error, {module(), String.t()}}

  def format(message, args \\ [], options \\ []) when is_binary(message) do
    options =
      default_options()
      |> Keyword.merge(options)

    options =
      if Keyword.has_key?(options, :backend) do
        options
      else
        Keyword.put(options, :backend, Cldr.default_backend())
      end

    with {:ok, result} <- Parser.parse(message) do
      {:ok, format_list(result, args, options) |> :erlang.iolist_to_binary}
    end
  rescue
    e -> inspect e; {:error, {ArgumentError, "Some error"}}
  end

  @spec format!(String.t(), arguments(), options()) :: String.t() | no_return

  def format!(message, args \\ [], options \\ []) when is_binary(message) do
    case format(message, args, options) do
      {:ok, message} -> :erlang.iolist_to_binary(message)
      {:error, {exception, reason}} -> raise exception, reason
    end
  end

  @doc """
  Formats an ICU message into an iolist

  """
  @spec format_list(list() | tuple(), arguments(), options()) :: list() | no_return

  def format_list(message, args \\ [], options \\ [])

  def format_list([head], args, options) do
    [format_to_string(format_list(head, args, options))]
  end

  def format_list([head | rest], args, options) do
    [format_to_string(format_list(head, args, options)) | format_list(rest, args, options)]
  end

  def format_list({:literal, literal}, _args, _options) when is_binary(literal) do
    [literal]
  end

  def format_list({:pos_arg, arg}, args, _options) when is_map(args) do
    [Map.fetch!(args, String.to_existing_atom(arg))]
  end

  def format_list({:pos_arg, arg}, args, _options) when is_list(args) do
    [Enum.at(args, arg)]
  end

  def format_list({:named_arg, arg}, args, _options) when is_map(args) do
    [Map.fetch!(args, String.to_existing_atom(arg))]
  end

  def format_list({:named_arg, arg}, args, _options) when is_list(args) do
    [Keyword.fetch!(args, String.to_existing_atom(arg))]
  end

  def format_list(:value, _args, options) do
    [Keyword.fetch!(options, :arg)]
  end

  def format_list({:simple_format, arg, type}, args, options) do
    [arg] = format_list(arg, args, options)
    format_list({arg, type}, args, options)
  end

  def format_list({:simple_format, arg, type, style}, args, options) do
    [arg] = format_list(arg, args, options)
    format_list({arg, type, style}, args, options)
  end

  def format_list({number, :number}, _args, options) do
    [Cldr.Number.to_string!(number, options)]
  end

  @integer_format "#"
  def format_list({number, :number, :integer}, _args, options) do
    options = Keyword.put(options, :format, @integer_format)
    [Cldr.Number.to_string!(number, options)]
  end

  def format_list({number, :number, :short}, _args, options) do
    options = Keyword.put(options, :format, :short)
    [Cldr.Number.to_string!(number, options)]
  end

  def format_list({number, :number, :currency}, _args, options) do
    options = Keyword.put(options, :format, :currency)
    [Cldr.Number.to_string!(number, options)]
  end

  def format_list({number, :number, :percent}, _args, options) do
    options = Keyword.put(options, :format, :percent)
    [Cldr.Number.to_string!(number, options)]
  end

  def format_list({number, :number, :permille}, _args, options) do
    options = Keyword.put(options, :format, :permille)
    [Cldr.Number.to_string!(number, options)]
  end

  def format_list({number, :number, format}, _args, options) when is_binary(format) do
    options = Keyword.put(options, :format, format)
    [Cldr.Number.to_string!(number, options)]
  end

  def format_list({number, :number, format}, _args, options) when is_atom(format) do
    format_options = configured_message_format(format, options[:backend])
    options = Keyword.merge(options, format_options)
    [Cldr.Number.to_string!(number, options)]
  end

  def format_list({number, :spellout}, _args, options) do
    options = Keyword.put(options, :format, :spellout)
    [Cldr.Number.to_string!(number, options)]
  end

  def format_list({number, :spellout, :verbose}, _args, options) do
    options = Keyword.put(options, :format, :spellout_verbose)
    [Cldr.Number.to_string!(number, options)]
  end

  def format_list({number, :spellout, :year}, _args, options) do
    options = Keyword.put(options, :format, :spellout_year)
    [Cldr.Number.to_string!(number, options)]
  end

  def format_list({number, :spellout, :ordinal}, _args, options) do
    options = Keyword.put(options, :format, :spellout_ordinal)
    [Cldr.Number.to_string!(number, options)]
  end

  if Code.ensure_loaded?(Cldr.Date) do
    def format_list({date, :date}, _args, options) do
      [Cldr.Date.to_string!(date, options)]
    end

    def format_list({date, :date, format}, _args, options) when is_binary(format) do
      options = Keyword.put(options, :format, format)
      [Cldr.Date.to_string!(date, options)]
    end

    def format_list({date, :date, format}, _args, options)
        when format in [:short, :medium, :long, :full] do
      options = Keyword.put(options, :format, format)
      [Cldr.Date.to_string!(date, options)]
    end

    def format_list({number, :date, format}, _args, options) when is_atom(format) do
      format_options = configured_message_format(format, options[:backend])
      options = Keyword.merge(options, format_options)
      [Cldr.Date.to_string!(number, options)]
    end

    def format_list({time, :time}, _args, options) do
      [Cldr.Time.to_string!(time, options)]
    end

    def format_list({time, :time, format}, _args, options) when is_binary(format) do
      options = Keyword.put(options, :format, format)
      [Cldr.Time.to_string!(time, options)]
    end

    def format_list({time, :time, format}, _args, options)
        when format in [:short, :medium, :long, :full] do
      options = Keyword.put(options, :format, format)
      [Cldr.Time.to_string!(time, options)]
    end

    def format_list({number, :time, format}, _args, options) when is_atom(format) do
      format_options = configured_message_format(format, options[:backend])
      options = Keyword.merge(options, format_options)
      [Cldr.Time.to_string!(number, options)]
    end

    def format_list({datetime, :datetime}, _args, options) do
      [Cldr.DateTime.to_string!(datetime, options)]
    end

    def format_list({datetime, :datetime, format}, _args, options) when is_binary(format) do
      options = Keyword.put(options, :format, format)
      [Cldr.DateTime.to_string!(datetime, options)]
    end

    def format_list({datetime, :datetime, format}, _args, options)
        when format in [:short, :medium, :long, :full] do
      options = Keyword.put(options, :format, format)
      [Cldr.DateTime.to_string!(datetime, options)]
    end

    def format_list({number, :datetime, format}, _args, options) when is_atom(format) do
      format_options = configured_message_format(format, options[:backend])
      options = Keyword.merge(options, format_options)
      [Cldr.DateTime.to_string!(number, options)]
    end
  else
    def format_list({_number, type, _format}, _args, _options)
        when type in [:date, :time, :datetime] do
      raise Cldr.Message.ParseError, datetime_configuration_error()
    end
  end

  if Code.ensure_loaded?(Money) do
    def format_list({money, :money, format}, _args, options) when format in [:short, :long] do
      options = Keyword.put(options, :format, format)
      [Money.to_string!(money, options)]
    end

    def format_list({number, :money, format}, _args, options) when is_atom(format) do
      format_options = configured_message_format(format, options[:backend])
      options = Keyword.merge(options, format_options)
      [Money.to_string!(number, options)]
    end
  else
    def format_list({_number, :money, _format}, _args, _options) do
      raise Cldr.Message.ParseError, money_configuration_error()
    end
  end

  if Code.ensure_loaded?(Cldr.Unit) do
    def format_list({unit, :unit}, _args, options) do
      [Cldr.Unit.to_string!(unit, options)]
    end

    def format_list({unit, :unit, format}, _args, options)
        when format in [:long, :short, :narrow] do
      options = Keyword.put(options, :format, format)
      [Cldr.Unit.to_string!(unit, options)]
    end

    def format_list({number, :unit, format}, _args, options) when is_atom(format) do
      format_options = configured_message_format(format, options[:backend])
      options = Keyword.merge(options, format_options)
      [Cldr.Unit.to_string!(number, options)]
    end
  else
    def format_list({_unit, :unit, _format}, _args, _options) do
      raise Cldr.Message.ParseError, unit_configuration_error()
    end
  end

  if Code.ensure_loaded?(Cldr.Date) do
    def format_list({list, :list}, _args, options) do
      [Cldr.List.to_string!(list, options)]
    end

    def format_list({list, :list, :and}, _args, options) do
      [Cldr.List.to_string!(list, options)]
    end

    @list_styles Cldr.List.known_list_styles()

    def format_list({list, :list, format}, _args, options) when format in @list_styles do
      options = Keyword.put(options, :format, format)
      [Cldr.List.to_string!(list, options)]
    end

    def format_list({number, :list, format}, _args, options) when is_atom(format) do
      format_options = configured_message_format(format, options[:backend])
      options = Keyword.merge(options, format_options)
      [Cldr.List.to_string!(number, options)]
    end
  else
    def format_list({_list, :list, _format}, _args, _options) do
      raise Cldr.Message.ParseError, list_configuration_error()
    end
  end

  def format_list({:select, arg, selections}, args, options) when is_map(selections) do
    arg =
      arg
      |> format_list(args, options)
      |> to_maybe_integer

    message = Map.get(selections, arg) || other(selections, arg)
    format_list(message, args, options)
  end

  def format_list({:plural, arg, {:offset, offset}, plurals}, args, options)
      when is_map(plurals) do
    format_plural(arg, Cardinal, offset, plurals, args, options)
  end

  def format_list({:select_ordinal, arg, plurals}, args, options) when is_map(plurals) do
    format_plural(arg, Ordinal, 0, plurals, args, options)
  end

  defp format_to_string([value]) do
    format_to_string(value)
  end

  defp format_to_string(value) when is_number(value) do
    Cldr.Number.to_string!(value)
  end

  defp format_to_string(%Decimal{} = value) do
    Cldr.Number.to_string!(value)
  end

  if Code.ensure_loaded?(Cldr.DateTime) do
    defp format_to_string(%Date{} = value) do
      Cldr.Date.to_string!(value)
    end

    defp format_to_string(%Time{} = value) do
      Cldr.Time.to_string!(value)
    end

    defp format_to_string(%DateTime{} = value) do
      Cldr.DateTime.to_string!(value)
    end
  end

  defp format_to_string(value) do
    Kernel.to_string(value)
  end

  defp format_plural(arg, type, offset, plurals, args, options) do
    arg =
      arg
      |> format_list(args, options)
      |> to_maybe_integer

    formatted_arg = Cldr.Number.to_string!(arg - offset, options)

    options =
      options
      |> Keyword.put(:type, type)
      |> Keyword.put(:arg, formatted_arg)

    plural_type = Cldr.Number.PluralRule.plural_type(arg - offset, options)
    message = Map.get(plurals, arg) || Map.get(plurals, plural_type) || other(plurals, arg)
    format_list(message, args, options)
  end

  @doc false
  def default_options do
    [locale: Cldr.get_locale()]
  end

  @spec other(map(), any()) :: any()
  defp other(map, _arg) when is_map(map) do
    Map.fetch!(map, "other")
  end

  @spec to_maybe_integer([number | Decimal.t() | String.t()]) ::
          number() | String.t() | atom()
  defp to_maybe_integer([arg]) when is_integer(arg) do
    arg
  end

  defp to_maybe_integer([arg]) when is_float(arg) do
    trunc(arg)
  end

  defp to_maybe_integer([%Decimal{} = arg]) do
    Decimal.to_integer(arg)
  end

  defp to_maybe_integer([other]) do
    other
  end

  @doc false
  def unit_configuration_error do
    """
    A `unit` formatting style cannot be applied unless the hex package `ex_cldr_units`
    is configured in `mix.exs`.
    """
  end

  @doc false
  def datetime_configuration_error do
    """
    A `date`, `time` or `datetime` formatting style cannot be applied unless the hex package
    `ex_cldr_dates_times` is configured in `mix.exs`.
    """
  end

  @doc false
  def money_configuration_error do
    """
    A `money` formatting style cannot be applied unless the hex package `ex_money`
    is configured in `mix.exs`.
    """
  end

  @doc false
  def list_configuration_error do
    """
    A `list` formatting style cannot be applied unless the hex package `ex_cldr_lists`
    is configured in `mix.exs`.
    """
  end
end
