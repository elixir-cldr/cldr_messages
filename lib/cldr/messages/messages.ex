defmodule Cldr.Message do
  @moduledoc """
  Implements the [ICU Message Format](http://userguide.icu-project.org/formatparse/messages)
  with functions to parse and interpolate messages.

  """
  alias Cldr.Message.{Parser, Interpreter, Print}
  import Kernel, except: [to_string: 1, binding: 1]
  defdelegate format_list(message, args, options), to: Interpreter
  defdelegate format_list!(message, args, options), to: Interpreter

  @type message :: binary()
  @type bindings :: list() | map()
  @type arguments :: bindings()
  @type options :: Keyword.t()

  @doc false
  def cldr_backend_provider(config) do
    Cldr.Message.Backend.define_message_module(config)
  end

  @doc """
  Returns the translation of the given ICU-formatted
  message string.

  Any placeholders are replaced with the value of variables
  already in scope at the time of compilation.

  `t/1` is a wrapper around the `gettext/2` macro
  which should therefore be imported from a `Gettext`
  backend prior to calling `t/1`.

  ## Arguments

  * `message` is an ICU format message string.

  ## Returns

  * A translated string.

  """
  defmacro t(message) when is_binary(message) do
    caller = __CALLER__.module
    canonical_message = Cldr.Message.canonical_message!(message, pretty: true)

    bindings =
      Enum.map(bindings(message), fn binding ->
        {String.to_atom(binding), {String.to_atom(binding), [if_undefined: :apply], caller}}
      end)

    quote do
      gettext(unquote(canonical_message), unquote(bindings))
    end
  end

  @doc """
  Returns the translation of the given ICU-formatted
  message string.

  `t/2` is a wrapper around the `gettext/2` macro
  which should therefore be imported from a `Gettext`
  backend prior to calling `t/2`.

  ## Arguments

  * `message` is an ICU format message string.

  * `bindings` is a keyword list or map of bindings used
    to replace placeholders in the message.

  ## Returns

  * A translated string.

  """
  defmacro t(message, bindings) when is_binary(message) do
    canonical_message = Cldr.Message.canonical_message!(message, pretty: true)

    quote do
      gettext(unquote(canonical_message), unquote(bindings))
    end
  end

  @doc """
  Format a message in the [ICU Message Format](https://unicode-org.github.io/icu/userguide/format_parse/messages)
  into a string.

  The ICU Message Format uses message `"pattern"` strings with
  variable-element placeholders enclosed in {curly braces}. The
  argument syntax can include formatting details, otherwise a
  default format is used.

  ## Arguments

  * `bindings` is a list or map of arguments that
    are used to replace placeholders in the message.

  * `options` is a keyword list of options.

  ## Options

  * `backend` is any `Cldr` backend. That is, any module that
    contains `use Cldr`.

  * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`.

  * `:trim` determines if the message is trimmed
    of whitespace before formatting. The default is
    `false`.

  * `:allow_positional_args` determines if position arguments
    are permitted. Positional arguments are in the format
    `{0}` in the message. The default is `true`.

  * All other aptions are passed to the `to_string/2`
    function of a formatting module.

  ## Returns

  * `{:ok, formatted_mesasge}` or

  * `{:error, {module, reason}}`

  ## Examples

      iex> Cldr.Message.format "{greeting} to you!", greeting: "Good morning"
      {:ok, "Good morning to you!"}

  """

  @spec format(String.t(), bindings(), options()) ::
          {:ok, String.t()} | {:error, {module(), String.t()}}

  def format(message, bindings \\ [], options \\ []) when is_binary(message) do
    case format_to_iolist(message, bindings, options) do
      {:ok, iolist, _bound, []} ->
        {:ok, :erlang.iolist_to_binary(iolist)}

      {:error, _iolist, _bound, unbound} ->
        {:error, {Cldr.Message.BindError, "No binding was found for #{inspect(unbound)}"}}

      other ->
        other
    end
  end

  @spec format!(String.t(), bindings(), options()) :: String.t() | no_return

  def format!(message, args \\ [], options \\ []) when is_binary(message) do
    case format(message, args, options) do
      {:ok, binary} ->
        binary

      {:error, {exception, reason}} ->
        raise exception, reason
    end
  end

  @doc """
  Format a message in the [ICU Message Format](https://unicode-org.github.io/icu/userguide/format_parse/messages)
  into an iolist.

  The ICU Message Format uses message `"pattern"` strings with
  variable-element placeholders enclosed in {curly braces}. The
  argument syntax can include formatting details, otherwise a
  default format is used.

  ## Arguments

  * `bindings` is a list or map of arguments that
    are used to replace placeholders in the message.

  * `options` is a keyword list of options.

  ## Options

  * `backend` is any `Cldr` backend. That is, any module that
    contains `use Cldr`.

  * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`.

  * `:trim` determines if the message is trimmed
    of whitespace before formatting. The default is
    `false`.

  * `:allow_positional_args` determines if position arguments
    are permitted. Positional arguments are in the format
    `{0}` in the message. The default is `true`.

  * All other aptions are passed to the `to_string/2`
    function of a formatting module.

  ## Returns

  * `{:ok, formatted_mesasge}` or

  * `{:error, {module, reason}}`

  ## Examples

      iex> Cldr.Message.format_to_iolist "{greeting} to you!", greeting: "Good morning"
      {:ok, ["Good morning", " to you!"], ["greeting"], []}

  """

  @spec format_to_iolist(String.t(), bindings(), options()) ::
          {:ok, list(), list(), list()}
          | {:error, list(), list(), list()}
          | {:error, {module(), binary()}}

  def format_to_iolist(message, bindings \\ [], options \\ []) when is_binary(message) do
    {locale, backend} = Cldr.locale_and_backend_from(options)

    options =
      default_options()
      |> Keyword.merge(options)
      |> Keyword.put_new(:locale, locale)
      |> Keyword.put_new(:backend, backend)

    with {:ok, message} <- maybe_trim(message, options[:trim]),
         {:ok, parsed} <- Parser.parse(message, options[:allow_positional_args]) do
      format_list(parsed, bindings, options)
    end
  rescue
    e in [Cldr.FormatCompileError, Cldr.Message.ParseError] ->
      {:error, {e.__struct__, e.message}}
  end

  @doc """
  Returns the [Jaro distance](https://en.wikipedia.org/wiki/Jaro–Winkler_distance)
  between two messages.

  This allows for fuzzy matching of message
  which can be helpful when a message string
  is changed but the semantics remain the same.

  ## Arguments

  * `message1` is a CLDR message in binary form.

  * `message2` is a CLDR message in binary form.

  * `options` is a keyword list of options. The
    default is `[]`.

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

      iex> Cldr.Message.jaro_distance "{greetings} to you!", "{greeting} to you!"
      {:ok, 0.9824561403508771}

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

  * `message1` is a CLDR message in binary form.

  * `message2` is a CLDR message in binary form.

  * `options` is a keyword list of options. The
    default is `[]`.

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

      iex> Cldr.Message.jaro_distance! "{greetings} to you!", "{greeting} to you!"
      0.9824561403508771

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

  * `message` is a CLDR message in binary form.

  * `options` is a keyword list of options. The
    default is `[]`.

  ## Options

  * `:trim` determines if the message is trimmed
    of whitespace before formatting. The default is
    `true`.

  * `:pretty` determines if the message if
    formatted with indentation to aid readability.
    The default is `false`.

  ## Returns

  * `{ok, canonical_message}` where `canonical_message`
    is a string or

  * `{:error, {exception, reason}}`

  ## Examples

      iex> Cldr.Message.canonical_message "{greeting } to you!"
      {:ok, "{greeting} to you!"}

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

  * `message` is a CLDR message in binary form.

  * `options` is a keyword list of options. The
    default is `[]`.

  ## Options

  * `:trim` determines if the message is trimmed
    of whitespace before formatting. The default is
    `true`.

  * `:pretty` determines if the message if
    formatted with indentation to aid readability.
    The default is `false`.

  ## Returns

  * `canonical_message` as a string or

  * raises an exception

  ## Examples

      iex> Cldr.Message.canonical_message! "{greeting } to you!"
      "{greeting} to you!"

  """
  def canonical_message!(message, options \\ []) do
    case canonical_message(message, options) do
      {:ok, message} -> message
      {:error, {exception, reason}} -> raise exception, reason
    end
  end

  @doc """
  Extract the binding names from an ICU message.

  ## Arguments

  * `message` is a CLDR message in binary or
    parsed form.

  ### Returns

  * A list of binding names as strings or

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
      {:simple_format, {_, arg}, _, _}, acc -> [arg | acc]
      {:select, {_, arg}, selectors}, acc -> [arg, bindings(selectors) | acc]
      {:plural, {_, arg}, _, selectors}, acc -> [arg, bindings(selectors) | acc]
      {:select_ordinal, {_, arg}, _, selectors}, acc -> [arg, bindings(selectors) | acc]
      _other, acc -> acc
    end)
    |> List.flatten()
    |> Enum.uniq()
  end

  def bindings(message) when is_map(message) do
    Enum.map(message, fn {_selector, message} -> bindings(message) end)
  end

  @doc false
  def default_options do
    [trim: false, allow_positional_args: true]
  end

  if Code.ensure_loaded?(Cldr) and function_exported?(Cldr, :default_backend!, 0) do
    @doc false
    def default_backend do
      Cldr.default_backend!()
    end
  else
    @doc false
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
