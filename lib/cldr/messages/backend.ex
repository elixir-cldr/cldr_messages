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
        def message_formats do
          unquote(Macro.escape(config.message_formats))
        end

        @doc """
        Returns the requested custom format or `nil`

        """
        def message_format(format) when is_atom(format) do
          Map.get(message_formats(), format)
        end
      end
    end
  end
end
