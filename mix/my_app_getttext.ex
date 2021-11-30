defmodule MyApp.Gettext do
  use Gettext, otp_app: :ex_cldr_messages, interpolation: MyApp.Cldr.Message
end

defmodule MyApp.Gettext.Use do
  import MyApp.Gettext

  def translate_compile_time(bindings \\ nil)

  # To test static bindings that can be interpolated at compile time
  # HOWEVER for some reason this is being called at runtime
  def translate_compile_time(nil), do: gettext("Goodbye {name}!", %{name: "José"})

  # To test dynamic bindings that cannot be interpolated at compile time
  def translate_compile_time(bindings), do: gettext("Hello {name}!", bindings)
end
