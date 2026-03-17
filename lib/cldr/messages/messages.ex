defmodule Cldr.Message do
  @moduledoc """
  Implements the [ICU Message Format](http://userguide.icu-project.org/formatparse/messages)
  with functions to parse and interpolate messages.

  Supports both ICU Message Format v1 and
  [Message Format 2](https://unicode.org/reports/tr35/tr35-messageFormat.html).

  Version detection is automatic: messages starting with `.` (`.input`,
  `.local`, `.match`) or `{{` are treated as MF2; everything else is v1.
  An explicit `:version` option (`:v1` or `:v2`) overrides detection.
  """
  alias Cldr.Message.V1
  alias Cldr.Message.V2

  import Kernel, except: [to_string: 1, binding: 1]
  defdelegate format_list(message, args, options), to: V1.Interpreter
  defdelegate format_list!(message, args, options), to: V1.Interpreter

  @doc """
  Detects whether a message string is MF2 (`:v2`) or legacy ICU (`:v1`).

  MF2 messages start with `.` (declarations/matcher) or `{{` (quoted pattern).

  ### Arguments

  * `message` is an ICU message string.

  ### Returns

  * `:v1` if the message is a legacy ICU Message Format string.

  * `:v2` if the message is an MF2 message.

  ### Examples

      iex> Cldr.Message.detect_version("Hello {name}")
      :v1

      iex> Cldr.Message.detect_version("{{Hello, world!}}")
      :v2

      iex> Cldr.Message.detect_version(".input {$count :number}\\n.match $count\\n  1 {{one}}\\n  * {{other}}")
      :v2

  """
  @spec detect_version(String.t()) :: :v1 | :v2
  def detect_version(message) when is_binary(message) do
    trimmed = String.trim_leading(message)

    cond do
      String.starts_with?(trimmed, ".") -> :v2
      String.starts_with?(trimmed, "{{") -> :v2
      true -> :v1
    end
  end

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

  ## Examples

      import MyApp.Gettext
      Cldr.Message.t("{greeting} to you!")

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

  ## Examples

      import MyApp.Gettext
      Cldr.Message.t("{greeting} to you!", greeting: "Good morning")

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

  * `:formatter_backend` determines which formatting engine to use
    for MF2 (v2) messages. Accepts `:default`, `:nif`, or `:elixir`.
    When set to `:default`, the ICU NIF is used if available, otherwise
    the pure-Elixir interpreter is used. When set to `:nif`, the NIF
    is required and a `RuntimeError` is raised if it is not available.
    When set to `:elixir`, the pure-Elixir interpreter is always used.
    The default is `:default`. This option has no effect on v1 messages.

  * All other options are passed to the `to_string/2`
    function of a formatting module.

  ## Returns

  * `{:ok, formatted_message}` or

  * `{:error, {module, reason}}`

  ## Examples

      iex> Cldr.Message.format "{greeting} to you!", greeting: "Good morning"
      {:ok, "Good morning to you!"}

  """

  @type formatter_backend :: :default | :nif | :elixir

  @spec format(String.t(), bindings(), options()) ::
          {:ok, String.t()} | {:error, {module(), String.t()}}

  def format(message, bindings \\ [], options \\ []) when is_binary(message) do
    version = Keyword.get(options, :version, detect_version(message))

    case version do
      :v2 -> format_v2(message, bindings, options)
      _ -> format_v1(message, bindings, options)
    end
  end

  defp format_v1(message, bindings, options) do
    case format_to_iolist_v1(message, bindings, options) do
      {:ok, iolist, _bound, []} ->
        {:ok, :erlang.iolist_to_binary(iolist)}

      {:error, _iolist, _bound, unbound} ->
        {:error, {Cldr.Message.BindError, "No binding was found for #{inspect(unbound)}"}}

      other ->
        other
    end
  end

  defp format_v2(message, bindings, options) do
    {formatter, options} = resolve_formatter_backend(options)

    case formatter do
      :nif -> format_v2_nif(message, bindings, options)
      :elixir -> format_v2_elixir(message, bindings, options)
    end
  end

  defp format_v2_elixir(message, bindings, options) do
    with {:ok, message} <- maybe_trim(message, options[:trim]),
         {:ok, parsed} <- V2.Parser.parse(message) do
      {locale, backend} = Cldr.locale_and_backend_from(options)

      v2_options =
        options
        |> Keyword.put_new(:locale, locale)
        |> Keyword.put_new(:backend, backend)

      case V2.Interpreter.format_list(parsed, bindings, v2_options) do
        {:ok, iolist, _bound, []} ->
          {:ok, :erlang.iolist_to_binary(iolist)}

        {:error, _iolist, _bound, unbound} ->
          {:error, {Cldr.Message.BindError, "No binding was found for #{inspect(unbound)}"}}

        {:format_error, reason} ->
          {:error, {Cldr.Message.FormatError, reason}}
      end
    end
  end

  defp format_v2_nif(message, bindings, options) do
    with {:ok, message} <- maybe_trim(message, options[:trim]) do
      locale_string = resolve_locale_string(options)
      bindings_map = normalize_bindings(bindings)

      case V2.Nif.format(message, locale_string, bindings_map) do
        {:ok, formatted} ->
          {:ok, formatted}

        {:error, reason} ->
          {:error, {Cldr.Message.ParseError, reason}}
      end
    end
  end

  defp resolve_formatter_backend(options) do
    {fb, rest} = Keyword.pop(options, :formatter_backend, :default)

    case fb do
      :nif ->
        unless V2.Nif.available?() do
          raise RuntimeError,
                "NIF formatter backend requested but not available. " <>
                  "Compile with CLDR_MESSAGES_MF2_NIF=true or set " <>
                  "`config :ex_cldr_messages, :mf2_nif, true` in config.exs."
        end

        {:nif, rest}

      :elixir ->
        {:elixir, rest}

      :default ->
        if V2.Nif.available?() do
          {:nif, rest}
        else
          {:elixir, rest}
        end
    end
  end

  defp resolve_locale_string(options) do
    case Keyword.get(options, :locale) do
      nil ->
        locale = Cldr.get_locale()
        Kernel.to_string(locale.cldr_locale_name)

      %Cldr.LanguageTag{cldr_locale_name: name} ->
        Kernel.to_string(name)

      name when is_binary(name) ->
        name

      name when is_atom(name) ->
        Atom.to_string(name)
    end
  end

  defp normalize_bindings(bindings) when is_map(bindings) do
    Map.new(bindings, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), v}
      {k, v} -> {k, v}
    end)
  end

  defp normalize_bindings(bindings) when is_list(bindings) do
    Map.new(bindings, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), v}
      {k, v} -> {k, v}
    end)
  end

  defp normalize_bindings(bindings), do: bindings

  @doc """
  Formats a message and returns the result or raises on error.

  Same as `format/3` but returns the formatted string directly
  or raises an exception.

  ## Examples

      iex> Cldr.Message.format! "{greeting} to you!", greeting: "Good morning"
      "Good morning to you!"

      iex> Cldr.Message.format! "{{Hello, world!}}"
      "Hello, world!"

  """
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

  * All other options are passed to the `to_string/2`
    function of a formatting module.

  ## Returns

  * `{:ok, formatted_message}` or

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
    format_to_iolist_v1(message, bindings, options)
  end

  defp format_to_iolist_v1(message, bindings, options) do
    {locale, backend} = Cldr.locale_and_backend_from(options)

    options =
      default_options()
      |> Keyword.merge(options)
      |> Keyword.put_new(:locale, locale)
      |> Keyword.put_new(:backend, backend)

    with {:ok, message} <- maybe_trim(message, options[:trim]),
         {:ok, parsed} <- V1.Parser.parse(message, options[:allow_positional_args]) do
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
  @spec jaro_distance(String.t(), String.t(), Keyword.t()) ::
          {:ok, float()} | {:error, {module(), String.t()}}

  def jaro_distance(message1, message2, options \\ []) do
    with {:ok, message1} <- maybe_trim(message1, options[:trim]),
         {:ok, message2} <- maybe_trim(message2, options[:trim]),
         {:ok, message1_ast} <- V1.Parser.parse(message1),
         {:ok, message2_ast} <- V1.Parser.parse(message2) do
      canonical_message1 = V1.Print.to_string(message1_ast)
      canonical_message2 = V1.Print.to_string(message2_ast)
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
  @spec jaro_distance!(String.t(), String.t(), Keyword.t()) :: float() | no_return

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
  @spec canonical_message(String.t(), Keyword.t()) ::
          {:ok, String.t()} | {:error, {module(), String.t()}}

  def canonical_message(message, options \\ []) do
    options = Keyword.put_new(options, :trim, true)
    version = Keyword.get(options, :version, detect_version(message))

    with {:ok, message} <- maybe_trim(message, options[:trim]) do
      case version do
        :v2 ->
          with {:ok, ast} <- V2.Parser.parse(message) do
            {:ok, V2.Print.to_string(ast, options)}
          end

        :v1 ->
          with {:ok, ast} <- V1.Parser.parse(message) do
            {:ok, V1.Print.to_string(ast, options)}
          end
      end
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
  @spec canonical_message!(String.t(), Keyword.t()) :: String.t() | no_return

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
  @spec bindings(String.t() | list() | map()) ::
          list(String.t()) | {:error, {module(), String.t()}}

  def bindings(message) when is_binary(message) do
    with {:ok, parsed} <- Cldr.Message.V1.Parser.parse(message) do
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
