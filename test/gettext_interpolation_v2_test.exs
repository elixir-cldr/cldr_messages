defmodule Cldr.Messages.GettextInterpolationV2Test do
  use ExUnit.Case

  alias MyApp.Gettext.V2.Use

  import Cldr.Message.TestHelpers

  test "message_format returns icu-format" do
    assert MyApp.Gettext.Interpolation.V2.message_format() == "icu-format"
  end

  test "interpolates compile time translation" do
    use Gettext, backend: MyApp.Gettext.V2

    assert "Hello World!" == Use.greeting("World")
  end

  test "runtime interpolation of simple V2 message" do
    use Gettext, backend: MyApp.Gettext.V2

    assert "Hello World!" == gettext("{{Hello {$name}!}}", %{"name" => "World"})
  end

  test "runtime interpolation of V2 message with number" do
    use Gettext, backend: MyApp.Gettext.V2

    result = gettext("{{You have {$count :number} items}}", %{"count" => 42})
    assert result =~ "42"
    assert result =~ "items"
  end

  test "runtime interpolation of V2 with declarations" do
    use Gettext, backend: MyApp.Gettext.V2

    assert "Hello World!" ==
             gettext(".input {$name}\n{{Hello {$name}!}}", %{"name" => "World"})
  end

  test "runtime interpolation of plain text V2 message" do
    use Gettext, backend: MyApp.Gettext.V2

    assert "Hello, world!" == gettext("{{Hello, world!}}")
  end

  test "V1 messages work through V2 interpolation module" do
    use Gettext, backend: MyApp.Gettext.V2

    assert "Hello World!" == gettext("Hello {name}!", name: "World")
  end

  test "runtime interpolation with missing bindings" do
    # When a binding is missing, the Elixir interpreter returns the
    # variable reference as a fallback string like "{$name}".
    use Gettext, backend: MyApp.Gettext.V2

    result = gettext("{{Hello {$name}!}}", %{})
    assert result =~ "{$name}"
  end

  test "runtime number formatting" do
    use Gettext, backend: MyApp.Gettext.V2

    with_no_default_backend(fn ->
      result = gettext("{{{$n :number}}}", %{"n" => 1234})
      assert result =~ "1"
      assert result =~ "234"
    end)
  end

  # The following tests use Cldr.Message.format with formatter_backend: :elixir
  # because the runtime gettext path may use the NIF backend (when available),
  # and the NIF does not support all MF2 functions (e.g. :currency, :unit, :date).
  # These tests verify the Elixir interpreter's formatting capabilities directly.

  test "currency formatting via elixir backend" do
    result =
      Cldr.Message.format("{{{$amount :currency currency=USD}}}", %{"amount" => 1},
        backend: MyApp.Cldr,
        locale: "en",
        formatter_backend: :elixir
      )

    assert {:ok, formatted} = result
    assert formatted =~ "$"
    assert formatted =~ "1"
  end

  test "date formatting via elixir backend" do
    result =
      Cldr.Message.format("{{{$d :date}}}", %{"d" => ~D[2022-01-22]},
        backend: MyApp.Cldr,
        locale: "en",
        formatter_backend: :elixir
      )

    assert {:ok, formatted} = result
    assert formatted =~ "Jan"
    assert formatted =~ "2022"
  end

  test "datetime formatting via elixir backend" do
    result =
      Cldr.Message.format("{{{$dt :datetime}}}", %{"dt" => ~U[2022-01-22T09:43:56.0Z]},
        backend: MyApp.Cldr,
        locale: "en",
        formatter_backend: :elixir
      )

    assert {:ok, formatted} = result
    assert formatted =~ "Jan"
    assert formatted =~ "2022"
    assert formatted =~ "9:43"
  end

  test "time formatting via elixir backend" do
    # The :time function expects a DateTime or NaiveDateTime, not a bare Time struct
    result =
      Cldr.Message.format("{{{$t :time}}}", %{"t" => ~N[2022-01-22T09:43:56]},
        backend: MyApp.Cldr,
        locale: "en",
        formatter_backend: :elixir
      )

    assert {:ok, formatted} = result
    assert formatted =~ "9:43"
  end

  test "unit formatting via elixir backend" do
    result =
      Cldr.Message.format("{{{$weight :unit unit=kilogram}}}", %{"weight" => 23},
        backend: MyApp.Cldr,
        locale: "en",
        formatter_backend: :elixir
      )

    assert {:ok, formatted} = result
    assert formatted =~ "23"
    assert formatted =~ "kilogram"
  end

  test "unit formatting with Cldr.Unit struct via elixir backend" do
    result =
      Cldr.Message.format("{{{$weight :unit}}}", %{"weight" => Cldr.Unit.new!("kilogram", 23)},
        backend: MyApp.Cldr,
        locale: "en",
        formatter_backend: :elixir
      )

    assert {:ok, formatted} = result
    assert formatted =~ "23"
    assert formatted =~ "kilogram"
  end

  test "compile time interpolation for French translation" do
    Gettext.put_locale(MyApp.Gettext.V2, "fr")
    Cldr.put_locale(MyApp.Cldr, "fr")

    assert Use.greeting("Marie") == "Bonjour Marie !"

    Gettext.put_locale(MyApp.Gettext.V2, "en")
    Cldr.put_locale(MyApp.Cldr, "en")
  end

  test "compile time interpolation for German translation" do
    Gettext.put_locale(MyApp.Gettext.V2, "de")
    Cldr.put_locale(MyApp.Cldr, "de")

    assert Use.greeting("Hans") == "Hallo Hans!"

    Gettext.put_locale(MyApp.Gettext.V2, "en")
    Cldr.put_locale(MyApp.Cldr, "en")
  end

  test "compile time interpolation for Japanese translation" do
    Gettext.put_locale(MyApp.Gettext.V2, "ja")
    Cldr.put_locale(MyApp.Cldr, "ja")

    assert Use.greeting("太郎") == "こんにちは太郎！"

    Gettext.put_locale(MyApp.Gettext.V2, "en")
    Cldr.put_locale(MyApp.Cldr, "en")
  end

  test "compile time number formatting uses locale" do
    Gettext.put_locale(MyApp.Gettext.V2, "de")
    Cldr.put_locale(MyApp.Cldr, "de")

    result = Use.item_count(1234)
    assert result =~ "1.234"

    Gettext.put_locale(MyApp.Gettext.V2, "en")
    Cldr.put_locale(MyApp.Cldr, "en")
  end

  test "compile time .match plural selection" do
    Cldr.put_locale(MyApp.Cldr, "en")
    Gettext.put_locale(MyApp.Gettext.V2, "en")

    assert Use.cart_message(0) == "Your cart is empty."
    assert Use.cart_message(1) == "You have one item."

    result = Use.cart_message(5)
    assert result =~ "5"
    assert result =~ "items"
  end

  test "compile time .match plural selection with French translation" do
    Gettext.put_locale(MyApp.Gettext.V2, "fr")
    Cldr.put_locale(MyApp.Cldr, "fr")

    assert Use.cart_message(0) == "Votre panier est vide."
    assert Use.cart_message(1) == "Vous avez un article."

    result = Use.cart_message(5)
    assert result =~ "5"
    assert result =~ "articles"

    Gettext.put_locale(MyApp.Gettext.V2, "en")
    Cldr.put_locale(MyApp.Cldr, "en")
  end
end
