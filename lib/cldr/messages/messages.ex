defmodule Cldr.Message do
  @moduledoc """
  Implements the [ICU Message Format](http://userguide.icu-project.org/formatparse/messages)
  with functions to parse and interpolate messages.

  """
  alias Cldr.Message.{Parser, Interpreter, Print}
  import Kernel, except: [to_string: 1, binding: 1]
  defdelegate format_list(message, args, options), to: Interpreter

  @type message :: binary()
  @type arguments :: list() | map()
  @type options :: Keyword.t()

  @doc false
  def cldr_backend_provider(config) do
    Cldr.Message.Backend.define_message_module(config)
  end

  @doc """
  Format a message in the [ICU Message Format](https://unicode-org.github.io/icu/userguide/format_parse/messages)

  The ICU Message Format uses message `"pattern"` strings with
  variable-element placeholders enclosed in {curly braces}. The
  argument syntax can include formatting details, otherwise a
  default format is used.

  ## Arguments

  * `args` is a list of map of arguments that
    are used to replace placeholders in the message

  * `options` is a keyword list of options

  ## Options

  * `:backend`

  * `:locale`

  * `:trim`

  * `:allow_positional_args`

  * All other aptions are passed to the `to_string/2`
    function of a formatting module

  ## Returns

  ## Examples

  """

  @spec format(String.t(), arguments(), options()) ::
          {:ok, String.t()} | {:error, {module(), String.t()}}

  def format(message, args \\ [],options \\ []) when is_binary(message) do
    options =
      default_options()
      |> Keyword.merge(options)

    options =
      if Keyword.has_key?(options, :backend) do
        options
      else
        Keyword.put(options, :backend, default_backend())
      end

    with {:ok, message} <- maybe_trim(message, options[:trim]),
         {:ok, parsed} <- Parser.parse(message, options[:allow_positional_args]) do
      {:ok, format_list(parsed, args, options) |> :erlang.iolist_to_binary()}
    end
  rescue
    e in [KeyError] ->
      {:error,
       {KeyError, "No argument binding was found for #{inspect(e.key)} in #{inspect(e.term)}"}}

    e in [Cldr.Message.ParseError, Cldr.FormatCompileError] ->
      {:error, {e.__struct__, e.message}}
  end

  @spec format!(String.t(), arguments(), options()) :: String.t() | no_return

  def format!(message, args \\ [], options \\ []) when is_binary(message) do
    case format(message, args, options) do
      {:ok, message} -> :erlang.iolist_to_binary(message)
      {:error, {exception, reason}} -> raise exception, reason
    end
  end

  @doc """
  Returns the [Jaro distance](https://en.wikipedia.org/wiki/Jaro–Winkler_distance)
  between two messages.

  This allows for fuzzy matching of message
  which can be helpful when a message string
  is changed but the semantics remain the same.

  ## Arguments

  * `message1` is a CLDR message in binary form

  * `message2` is a CLDR message in binary form

  * `options` is a keyword list of options. The
    default is `[]`

  ## Options

  * `:trim` determines if the message is trimmed
    of whitespace before formatting. The default is
    `false`.

  ## Returns

  * `{ok, distance}` where `distance` is a float value between 0.0
    (equates to no similarity) and 1.0 (is an
    exact match) representing Jaro distance between `message1`
    and `message2` or

  * `{:error, {exception, reason}}`

  ## Examples

  """
  def jaro_distance(message1, message2, options \\ []) do
    with {:ok, message1} <- maybe_trim(message1, options[:trim]),
         {:ok, message2} <- maybe_trim(message2, options[:trim]),
         {:ok, message1_ast} <- Parser.parse(message1),
         {:ok, message2_ast} <- Parser.parse(message2) do
      canonical_message1 = Print.to_string(message1_ast)
      canonical_message2 = Print.to_string(message2_ast)
      {:ok, String.jaro_distance(canonical_message1, canonical_message2)}
    end
  end

  @doc """
  Returns the [Jaro distance](https://en.wikipedia.org/wiki/Jaro–Winkler_distance)
  between two messages or raises.

  This allows for fuzzy matching of message
  which can be helpful when a message string
  is changed but the semantics remain the same.

  ## Arguments

  * `message1` is a CLDR message in binary form

  * `message2` is a CLDR message in binary form

  * `options` is a keyword list of options. The
    default is `[]`

  ## Options

  * `:trim` determines if the message is trimmed
    of whitespace before formatting. The default is
    `false`.

  ## Returns

  * `distance` where `distance` is a float value between 0.0
    (equates to no similarity) and 1.0 (is an
    exact match) representing Jaro distance between `message1`
    and `message2` or

  * raises an exception

  ## Examples

  """
  def jaro_distance!(message1, message2, options \\ []) do
    case jaro_distance(message1, message2, options) do
      {:ok, distance} -> distance
      {:error, {exception, reason}} -> raise exception, reason
    end
  end

  @doc """
  Formats a message into a canonical form.

  This allows for messages to be compared
  directly, or using `Cldr.Message.jaro_distance/3`.

  ## Arguments

  * `message` is a CLDR message in binary form

  * `options` is a keyword list of options. The
    default is `[]`

  ## Options

  * `:trim` determines if the message is trimmed
    of whitespace before formatting. The default is
    `true`.

  * `:pretty` determines if the message if
    formatted with indentation to aid readability.
    The default is `false`.

  ## Returns

  * `{ok, canonical_message}` where `canonical_message`
    is a binary or

  * `{:error, {exception, reason}}`

  ## Examples

  """
  def canonical_message(message, options \\ []) do
    options = Keyword.put_new(options, :trim, true)

    with {:ok, message} <- maybe_trim(message, options[:trim]),
         {:ok, message_ast} <- Parser.parse(message) do
      {:ok, Print.to_string(message_ast, options)}
    end
  end

  @doc """
  Formats a message into a canonical form
  or raises if the message cannot be parsed.

  This allows for messages to be compared
  directly, or using `Cldr.Message.jaro_distance/3`.

  ## Arguments

  * `message` is a CLDR message in binary form

  * `options` is a keyword list of options. The
    default is `[]`

  ## Options

  * `:trim` determines if the message is trimmed
    of whitespace before formatting. The default is
    `true`.

  * `:pretty` determines if the message if
    formatted with indentation to aid readability.
    The default is `false`.

  ## Returns

  * `canonical_message` where `canonical_message`
    is a binary or

  * raises an exception

  ## Examples

  """
  def canonical_message!(message, options \\ []) do
    case canonical_message(message, options) do
      {:ok, message} -> message
      {:error, {exception, reason}} -> raise exception, reason
    end
  end

  @doc """
  Extract the binding names from a
  parsed message

  ## Arguments

  * `message` is a CLDR message in binary or
    parsed form

  ### Returns

  * A list of variable names or

  * `{:error, {exception, reason}}`

  ### Examples

       iex> Cldr.Message.bindings "This {variable} is in the message"
       ["variable"]

  """
  def bindings(message) when is_binary(message) do
    with {:ok, parsed} <- Cldr.Message.Parser.parse(message) do
      bindings(parsed)
    end
  end

  def bindings(message) when is_list(message) do
    Enum.reduce(message, [], fn
      {:named_arg, arg}, acc -> [arg | acc]
      {:pos_arg, arg}, acc -> [arg | acc]
      {:select, {_, arg}, selectors}, acc -> [arg, bindings(selectors) | acc]
      {:plural, {_, arg}, _, selectors}, acc -> [arg, bindings(selectors) | acc]
      {:select_ordinal, {_, arg}, _, selectors}, acc -> [arg, bindings(selectors) | acc]
      _other, acc-> acc
    end)
    |> List.flatten
    |> Enum.uniq
  end

  def bindings(message) when is_map(message) do
    Enum.map(message, fn {_selector, message} -> bindings(message) end)
  end
  @doc false
  def default_options do
    [locale: Cldr.get_locale(), trim: false]
  end

  if Code.ensure_loaded?(Cldr) and function_exported?(Cldr, :default_backend!, 0) do
    def default_backend do
      Cldr.default_backend!()
    end
  else
    def default_backend do
      Cldr.default_backend()
    end
  end

  defp maybe_trim(message, true) do
    {:ok, String.trim(message)}
  end

  defp maybe_trim(message, _) do
    {:ok, message}
  end
end
