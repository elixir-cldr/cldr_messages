defmodule Cldr.Formatter.Plugin do
  @moduledoc """
  A CLDR/ICU message formatter for mix format plugin.

  ## Usage

  Add `Cldr.Formatter.Plugin` to the `:plugins` in `.formatter.exs`:
  ```
  [
    plugins: [Cldr.Formatter.Plugin]
    # ...
  ]
  ```
  And then when you run `mix format`, it'll format CLDR messages `~M`
  sigils.

  """

  @behaviour Mix.Tasks.Format

  @impl true
  def features(_opts) do
    [sigils: [:M]]
  end

  @impl true
  def format(contents, opts) do
    opts = Keyword.put_new(opts, :pretty, true)
    formatted = Cldr.Message.canonical_message!(contents, opts)
    if String.ends_with?(contents, "\n") do
      formatted <> "\n"
    else
      formatted
    end
  end
end
