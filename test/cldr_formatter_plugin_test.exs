defmodule Cldr.Formatter.PluginTest do
  @moduledoc false

  use ExUnit.Case

  for input_filename <-
        Path.wildcard(Application.app_dir(:ex_cldr_messages, "priv/test/formatter/input/*.exs")) do
    name = Path.basename(input_filename, ".exs")

    expected_filename =
      Application.app_dir(:ex_cldr_messages, "priv/test/formatter/expected/#{name}.exs")

    input = File.read!(input_filename)
    expected = File.read!(expected_filename)

    test name do
      {formatter, _opts} = Mix.Tasks.Format.formatter_for_file(unquote(input_filename))
      assert formatter.(unquote(input)) == unquote(expected)
    end
  end
end
