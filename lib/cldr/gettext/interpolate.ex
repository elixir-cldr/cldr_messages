defmodule Cldr.Gettext.Interpolation do
  defmacro __using__(opts \\ []) do
    backend = Keyword.get_lazy(opts, :cldr_backend, &Cldr.default_backend!/0)

    quote do
      @behaviour Gettext.Interpolation

      @icu_format "icu-format"

      @impl Gettext.Interpolation
      def runtime_interpolate(message, bindings) when is_binary(message) do
        Cldr.maybe_log("Run time: #{inspect(message)}")
        options = [backend: unquote(backend), locale: Cldr.get_locale(unquote(backend))]
        Cldr.Message.Backend.gettext_interpolate(message, bindings, options)
      end

      @impl Gettext.Interpolation
      defmacro compile_interpolate(_translation_type, message, bindings) do
        alias Cldr.Message.Parser
        alias Cldr.Message.Backend

        backend = unquote(backend)
        message = Backend.expand_to_binary!(message, __CALLER__)

        Cldr.maybe_log("Compile time: #{inspect(message)}")

        case Cldr.Message.Parser.parse(message) do
          {:ok, parsed_message} ->
            Backend.validate_bindings!(parsed_message, bindings)
            static_bindings = Backend.static_bindings(bindings)
            Backend.quoted_message(parsed_message, backend, bindings, static_bindings)

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
