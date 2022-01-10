defmodule Cldr.Message.TestHelpers do
  def with_no_default_backend(fun) do
    current_default = Application.get_env(:ex_cldr, :default_backend)

    try do
      fun.()
    after
      Application.put_env(:ex_cldr, :default_backend, current_default)
    end
  end

end