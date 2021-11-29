defmodule Cldr.Messages.GettextInterpolationtest do
  use ExUnit.Case

  alias MyApp.Gettext.Use

  import ExUnit.CaptureLog
  import MyApp.Gettext

  test "interpolates compile time translation" do
    assert "Hello World!" == Use.translate_compile_time(name: "World")

    assert capture_log(fn ->
             Use.translate_compile_time(%{})
           end) =~ "missing Gettext bindings: [\"name\"]"
  end

  test "interpolates runtime translation" do
    assert "runtime MXP 1.00" ==
             gettext("runtime {one, number, currency}", %{one: {1, currency: :MXP}})

    assert capture_log(fn ->
             assert "runtime {one, number, currency}" ==
                      gettext("runtime {one, number, currency}", %{})
           end) =~ "missing Gettext bindings: [\"one\"]"
  end
end
