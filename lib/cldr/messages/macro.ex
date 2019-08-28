defmodule Cldr.Message.Macro do
  defmacro format(message, bindings \\ [], options \\ []) do
    alias Cldr.Message.Parser

    message = expand_to_binary(message, __CALLER__)
    options = Keyword.merge(Cldr.Message.default_options(), options)

    case Parser.parse(message) do
      {:ok, parsed_message} ->
        quote do
          Cldr.Message.format(
            unquote(parsed_message),
            unquote(bindings),
            unquote(Macro.escape(options))
          )
          |> :erlang.iolist_to_binary()
        end

      {:error, {exception, reason}} ->
        raise exception, reason
    end
  end

  @doc """
  Expands the given `msgid` in the given `env`, raising if it doesn't expand to
  a binary.
  """
  @spec expand_to_binary(binary, Macro.Env.t()) :: binary | no_return
  def expand_to_binary(term, env) do
    raiser = fn term ->
      raise ArgumentError, """
      Message macros expect translation keys to expand to strings at compile-time, but the given
      doesn't. This is what the macro received:

        #{inspect(term)}

      Dynamic translations should be avoided as they limit the
      ability to extract translations from your source code. If you are
      sure you need dynamic lookup, you can use the functions in the Cldr.Message
      module:

        string = "hello world"
        Cldr.Message(string)

      """
    end

    case Macro.expand(term, env) do
      term when is_binary(term) ->
        term

      {:<<>>, _, pieces} = term ->
        if Enum.all?(pieces, &is_binary/1), do: Enum.join(pieces), else: raiser.(term)

      other ->
        raiser.(other)
    end
  end
end
