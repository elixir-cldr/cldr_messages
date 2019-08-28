defmodule Cldr.Message.Backend do
  def define_message_module(config) do
    module = inspect(__MODULE__)
    backend = config.backend
    config = Macro.escape(config)

    quote location: :keep, bind_quoted: [module: module, backend: backend, config: config] do
      defmodule Message do
        @moduledoc false
        if Cldr.Config.include_module_docs?(config.generate_docs) do
          @moduledoc """
          Supports the CLDR Message format

          """
        end

        @doc """
        Returns a map of configured custom message formats

        """
        def configured_message_formats do
          unquote(Macro.escape(config.message_formats))
        end

        @doc """
        Returns the requested custom format or `nil`

        """
        def configured_message_format(format) when is_atom(format) do
          Map.get(configured_message_formats(), format)
        end

        @doc """
        Formats an ICU message

        This macro parses the message at compile time in
        order to optimize performance a runtime.

        See `Cldr.Message.format/3` for details on the
        arguments and options

        """
        defmacro format(message, bindings \\ [], options \\ []) do
          alias Cldr.Message.Parser

          message = Cldr.Message.Backend.expand_to_binary(message, __CALLER__)
          backend = unquote(Macro.escape(config)) |> Map.get(:backend)

          case Parser.parse(message) do
            {:ok, parsed_message} ->
              quote do
                options =
                  unquote(options)
                  |> Keyword.put(:backend, unquote(backend))
                  |> Keyword.put_new(:locale, Cldr.get_locale(unquote(backend)))

                unquote(parsed_message)
                |> Cldr.Message.format(unquote(bindings), options)
                |> :erlang.iolist_to_binary()
              end

            {:error, {exception, reason}} ->
              raise exception, reason
          end
        end
      end
    end
  end

  @doc """
  Expands the given `message` in the given `env`, raising if it doesn't expand to
  a binary.
  """
  @spec expand_to_binary(binary, Macro.Env.t()) :: binary | no_return
  def expand_to_binary(term, env) do
    raiser = fn term ->
      raise ArgumentError, """
      Cldr.Message macros expect translation keys to expand to strings at compile-time, but the
      given doesn't. This is what the macro received:

        #{inspect(term)}

      Dynamic translations should be avoided as they limit the
      ability to extract translations from your source code. If you are
      sure you need dynamic lookup, you can use the functions in the Cldr.Message
      module:

        string = "hello world"
        Cldr.Message.format(string)

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
