defmodule Cldr.Messages.GettextInterpolationV2Test do
  use ExUnit.Case

  test "message_format returns icu-format" do
    assert MyApp.Gettext.Interpolation.V2.message_format() == "icu-format"
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
end
