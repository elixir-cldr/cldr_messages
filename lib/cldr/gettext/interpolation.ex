defmodule Cldr.Gettext.Interpolation do
  @moduledoc """
  As of [Gettext 0.19](https://hex.pm/packages/gettext/0.19.0), `Gettext`
  supports user-defined [interpolation modules](https://hexdocs.pm/gettext/Gettext.html#module-backend-configuration).
  This makes it easy to combine the power of ICU message formats with the
  broad `gettext` ecosystem and the inbuilt support for `gettext`
  in [Phoenix](https://hex.pm/packages/phoenix).

  The documentation for [Gettext](https://hexdocs.pm/gettext/Gettext.html#content)
  should be followed with considerations in mind:

  1. A Gettext backend module should use the `:interpolation` option
     defined referring to the `ex_cldr_messages` backend you have defined.
  2. The message format is in the ICU message format (instead of the Gettext format).

  ### Defining a Gettext Interpolation Module

  Any [ex_cldr](https://hex.pm/packages/ex_cldr) [backend module](https://hexdocs.pm/ex_cldr/readme.html#backend-module-configuration) that has a `Cldr.Message` provider configured can be used as an interpolation module. Here is an example:
  ```elixir
  # CLDR backend module
  defmodule MyApp.Cldr do
    use Cldr,
      locales: ["en", "fr", "ja", "he", "th", "ar"],
      default_locale: "en",
      providers: [Cldr.Number, Cldr.DateTime, Cldr.Unit, Cldr.List, Cldr.Calendar, Cldr.Message],
      gettext: MyApp.Gettext,
      message_formats: %{
        USD: [format: :long]
      }
  end

  # Define an interpolation module for ICU messages
  defmodule MyApp.Gettext.Interpolation do
    use Cldr.Gettext.Interpolation, cldr_backend: MyApp.Cldr

  end

  # Define a gettext module with ICU message interpolation
  defmodule MyApp.Gettext do
    use Gettext, otp_app: :ex_cldr_messages, interpolation: MyApp.Gettext.Interpolation
  end

  ```
  Now you can proceed to use `Gettext` in the normal manner, most
  typically with the `gettext/3` macro.

  """
  defmacro __using__(opts \\ []) do
    backend = Keyword.get_lazy(opts, :cldr_backend, &Cldr.default_backend!/0)

    quote do
      @behaviour Gettext.Interpolation

      @icu_format "icu-format"

      @impl Gettext.Interpolation
      def runtime_interpolate(message, bindings) when is_binary(message) do
        options = [backend: unquote(backend), locale: Cldr.get_locale(unquote(backend))]
        Cldr.Message.Backend.gettext_interpolate(message, bindings, options)
      end

      @impl Gettext.Interpolation
      defmacro compile_interpolate(_translation_type, message, bindings) do
        alias Cldr.Message.Parser
        alias Cldr.Message.Backend

        backend = unquote(backend)
        message = Backend.expand_to_binary!(message, __CALLER__)

        case Cldr.Message.Parser.parse(message) do
          {:ok, parsed_message} ->
            quote do
              options = [backend: unquote(backend), locale: Cldr.get_locale(unquote(backend))]
              Cldr.Message.Backend.gettext_interpolate(unquote(Macro.escape(parsed_message)), unquote(bindings), options)
            end

          {:error, {exception, reason}} ->
            raise exception, reason
        end
      end

      @impl Gettext.Interpolation
      def message_format do
        @icu_format
      end
    end
  end
end
