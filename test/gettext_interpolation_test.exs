defmodule Cldr.Messages.GettextInterpolationtest do
  use ExUnit.Case

  alias MyApp.Gettext.Use

  import ExUnit.CaptureLog
  import Cldr.Message.TestHelpers

  test "interpolates compile time translation" do
    use Gettext, backend: MyApp.Gettext

    assert "Hello World!" == Use.translate_compile_time(name: "World")

    assert capture_log(fn ->
             Use.translate_compile_time(%{})
           end) =~ "missing Gettext bindings: [\"name\"]"
  end

  test "interpolates runtime translation" do
    use Gettext, backend: MyApp.Gettext

    assert "runtime MXP 1.00" ==
             gettext("runtime {one, number, currency}", %{one: {1, currency: :MXP}})

    assert capture_log(fn ->
             assert "runtime {one, number, currency} two" ==
                      gettext("runtime {one, number, currency} {two}", %{two: "two"})
           end) =~ "missing Gettext bindings: [\"one\"]"
  end

  test "interpolates runtime translation with backend that has no message formats configured" do
    use Gettext, backend: MyApp.Gettext

    assert "runtime MXP 1.00" ==
             gettext("runtime {one, number, currency}", %{one: {1, currency: :MXP}})

    assert capture_log(fn ->
             assert "runtime {one, number, currency}" ==
                      gettext("runtime {one, number, currency}", %{})
           end) =~ "missing Gettext bindings: [\"one\"]"
  end

  test "interpolation with sigil_m" do
    use Gettext, backend: MyApp.Gettext
    import Cldr.Message.Sigil

    assert gettext(~m"runtime {one, number, currency}", %{one: {1, currency: :MXP}}) ==
             gettext(~m"runtime {one,   number,   currency}", %{one: {1, currency: :MXP}})

    assert capture_log(fn ->
             assert "runtime {one, number, currency} two" ==
                      gettext(~m"runtime {one, number, currency} {two}", %{two: "two"})
           end) =~ "missing Gettext bindings: [\"one\"]"
  end

  test "number formatting in gettext finds the CLDR backend" do
    use Gettext, backend: MyApp.Gettext

    with_no_default_backend(fn ->
      assert gettext("Message {number}", number: 7) == "Message 7"
    end)
  end

  test "Compile time interpolation for translation" do
    Gettext.put_locale MyApp.Gettext, "fr"
    Cldr.put_locale MyApp.Cldr, "fr"

    assert MyApp.Gettext.Use.translate_complex() == "Il est votre 2e jab"

    Gettext.put_locale MyApp.Gettext, "en"
    Cldr.put_locale MyApp.Cldr, "en"
  end

  test "datetime interpolation" do
    use Gettext, backend: MyApp.Gettext

    with_no_default_backend(fn ->
      assert gettext("Created at {created_at}", created_at: ~D[2022-01-22]) ==
        "Created at Jan 22, 2022"
      assert gettext("Created at {created_at}", created_at: ~U[2022-01-22T09:43:56.0Z]) ==
        "Created at Jan 22, 2022, 9:43:56 AM"
      assert gettext("Created at {created_at}", created_at: ~T[09:43:56]) ==
        "Created at 9:43:56 AM"
    end)
  end

  test "unit interpolation" do
    use Gettext, backend: MyApp.Gettext
    Cldr.put_locale MyApp.Cldr, "en"

    with_no_default_backend(fn ->
      assert gettext("It weighs {weight}", weight: Cldr.Unit.new!("kilogram", 23)) == "It weighs 23 kilograms"
      assert gettext("It weighs {weight, unit}", weight: Cldr.Unit.new!("kilogram", 23)) == "It weighs 23 kilograms"
    end)
  end
end
