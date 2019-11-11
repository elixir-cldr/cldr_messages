defmodule Cldr.Message do
  @moduledoc """
  Implements the [ICU Message Format](http://userguide.icu-project.org/formatparse/messages)
  with functions to parse and interpolate messages.

  """
  alias Cldr.Message.{Parser, Interpreter, Print}
  import Kernel, except: [to_string: 1]
  defdelegate format_list(message, args, options), to: Interpreter

  @type message :: binary()
  @type arguments :: list() | map()
  @type options :: Keyword.t()

  @doc false
  def cldr_backend_provider(config) do
    Cldr.Message.Backend.define_message_module(config)
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

    with {:ok, message} <- maybe_trim(message, options[:trim]),
         {:ok, result} <- Parser.parse(message) do
      {:ok, format_list(result, args, options) |> :erlang.iolist_to_binary()}
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

  def jaro_distance(message1, message2, options \\ []) do
    with {:ok, message1} <- maybe_trim(message1, options[:trim]),
         {:ok, message2} <- maybe_trim(message2, options[:trim]),
         {:ok, message1_ast} <- Parser.parse(message1),
         {:ok, message2_ast} <- Parser.parse(message2) do
       canonical_message1 = Print.to_string(message1_ast)
       canonical_message2 = Print.to_string(message2_ast)
       String.jaro_distance(canonical_message1, canonical_message2)
    end
  end

  @doc false
  def default_options do
    [locale: Cldr.get_locale(), trim: false]
  end

  defp maybe_trim(message, true) do
    {:ok, String.trim(message)}
  end

  defp maybe_trim(message, _) do
    {:ok, message}
  end
end
