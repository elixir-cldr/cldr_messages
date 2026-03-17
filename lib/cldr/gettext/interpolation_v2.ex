defmodule Cldr.Gettext.Interpolation.V2 do
  @moduledoc """
  Gettext interpolation module that supports both ICU MessageFormat v1
  and MessageFormat 2 (MF2) messages.

  Messages are compiled as V2 first; if the V2 parser fails, the V1
  parser is tried as a fallback. At runtime, `Cldr.Message.format/3`
  auto-detects the version. This allows the same `.POT` files to
  contain both v1 and v2 messages, all tagged with `icu-format`.

  ### Defining a Gettext Interpolation Module

  ```elixir
  # CLDR backend module
  defmodule MyApp.Cldr do
    use Cldr,
      locales: ["en", "fr", "ja"],
      default_locale: "en",
      providers: [Cldr.Number, Cldr.Message],
      gettext: MyApp.Gettext
  end

  # Define an interpolation module that handles both v1 and v2
  defmodule MyApp.Gettext.Interpolation do
    use Cldr.Gettext.Interpolation.V2, cldr_backend: MyApp.Cldr
  end

  # Define a gettext module
  defmodule MyApp.Gettext do
    use Gettext, otp_app: :my_app, interpolation: MyApp.Gettext.Interpolation
  end
  ```

  Now you can use `Gettext` with both message formats:

      # V1 message
      gettext("{greeting} world!", greeting: "Hello")
      #=> "Hello world!"

      # V2 message (auto-detected by leading `{{`)
      gettext("{{Hello {$name}!}}", %{"name" => "World"})
      #=> "Hello World!"

  """
  defmacro __using__(opts \\ []) do
    backend = Keyword.get_lazy(opts, :cldr_backend, &Cldr.default_backend!/0)

    quote do
      @behaviour Gettext.Interpolation

      @impl Gettext.Interpolation
      def runtime_interpolate(message, bindings) when is_binary(message) do
        options = [backend: unquote(backend), locale: Cldr.get_locale(unquote(backend))]
        Cldr.Message.Backend.gettext_interpolate_auto(message, bindings, options)
      end

      @impl Gettext.Interpolation
      defmacro compile_interpolate(_translation_type, message, bindings) do
        alias Cldr.Message.Backend

        backend = unquote(backend)
        message = Backend.expand_to_binary!(message, __CALLER__)

        # Try V2 first, fall back to V1 on parse error
        case Cldr.Message.V2.Parser.parse(message) do
          {:ok, parsed_message} ->
            quote do
              options = [backend: unquote(backend), locale: Cldr.get_locale(unquote(backend))]

              Cldr.Message.Backend.gettext_interpolate_v2(
                unquote(Macro.escape(parsed_message)),
                unquote(bindings),
                options
              )
            end

          {:error, _v2_reason} ->
            case Cldr.Message.V1.Parser.parse(message) do
              {:ok, parsed_message} ->
                quote do
                  options = [backend: unquote(backend), locale: Cldr.get_locale(unquote(backend))]

                  Cldr.Message.Backend.gettext_interpolate(
                    unquote(Macro.escape(parsed_message)),
                    unquote(bindings),
                    options
                  )
                end

              {:error, {exception, reason}} ->
                raise exception, reason
            end
        end
      end

      @impl Gettext.Interpolation
      def message_format, do: "icu-format"
    end
  end
end
