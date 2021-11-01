defmodule MyApp.Gettext do
  use Gettext, otp_app: :ex_cldr_messages, interpolation: MyApp.Cldr.Message
end

defmodule MyApp.Gettext.Use do
  import MyApp.Gettext

  def translate_compile_time(bindings), do: gettext("Hello {name}!", bindings)
end
