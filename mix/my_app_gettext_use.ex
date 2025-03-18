defmodule MyApp.Gettext.Use do
  use Gettext, backend: MyApp.Gettext

  def translate_compile_time(bindings \\ nil)

  # To test static bindings that can be interpolated at compile time
  # HOWEVER for some reason this is being called at runtime
  def translate_compile_time(nil), do: gettext("Goodbye {name}!", %{name: "José"})

  # To test dynamic bindings that cannot be interpolated at compile time
  def translate_compile_time(bindings), do: gettext("Hello {name}!", bindings)

  # Test complex bindings
  def translate_complex(), do: gettext("This is your {count, number, ordinal} jab", count: 2)
end
