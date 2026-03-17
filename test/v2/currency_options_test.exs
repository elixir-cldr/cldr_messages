defmodule Cldr.Message.V2.CurrencyOptionsTest do
  use ExUnit.Case, async: true

  alias Cldr.Message.V2.{Parser, Interpreter}

  defp format(src, bindings) do
    {:ok, parsed} = Parser.parse(src)
    options = [backend: MyApp.Cldr, locale: "en-US"]

    case Interpreter.format_list(parsed, bindings, options) do
      {:ok, iolist, _, _} -> :erlang.iolist_to_binary(iolist)
      {:error, iolist, _, _} -> :erlang.iolist_to_binary(iolist)
    end
  end

  describe "currency formatting" do
    test "basic currency with currency code" do
      assert format("{$amount :currency currency=USD}", %{"amount" => 42.50}) == "$42.50"
    end

    test "currency with integer value" do
      assert format("{$amount :currency currency=EUR}", %{"amount" => 100}) == "€100.00"
    end

    test "currency with string value" do
      assert format("{$amount :currency currency=USD}", %{"amount" => "42.50"}) == "$42.50"
    end
  end

  describe "currencyDisplay option" do
    test "narrowSymbol displays narrow currency symbol" do
      assert format(
               "{$amount :currency currency=USD currencyDisplay=narrowSymbol}",
               %{"amount" => 42.50}
             ) == "$42.50"
    end

    test "code displays ISO currency code" do
      result =
        format(
          "{$amount :currency currency=USD currencyDisplay=code}",
          %{"amount" => 42.50}
        )

      # CLDR uses non-breaking space (U+00A0) between ISO code and number
      assert result == "USD\u00A042.50"
    end

    test "default displays standard currency symbol" do
      assert format("{$amount :currency currency=EUR}", %{"amount" => 42.50}) == "€42.50"
    end
  end

  describe "currencySign option" do
    test "accounting wraps negative values in parentheses" do
      assert format(
               "{$amount :currency currency=USD currencySign=accounting}",
               %{"amount" => -42.50}
             ) == "($42.50)"
    end

    test "standard uses minus sign for negative values" do
      result = format("{$amount :currency currency=USD}", %{"amount" => -42.50})
      assert result =~ "-"
      assert result =~ "42.50"
    end

    test "accounting with positive value formats normally" do
      assert format(
               "{$amount :currency currency=USD currencySign=accounting}",
               %{"amount" => 42.50}
             ) == "$42.50"
    end
  end

  describe "combined options" do
    test "currencyDisplay=code with currencySign=accounting" do
      result =
        format(
          "{$amount :currency currency=USD currencyDisplay=code currencySign=accounting}",
          %{"amount" => -42.50}
        )

      assert result =~ "USD"
      assert result =~ "42.50"
      # Accounting format wraps in parentheses
      assert result =~ "("
    end

    test "currency with minimumFractionDigits" do
      assert format(
               "{$amount :currency currency=USD minimumFractionDigits=0}",
               %{"amount" => 42}
             ) == "$42"
    end
  end

  describe "Money struct" do
    test "derives currency from Money struct" do
      money = Money.new(:USD, "42.50")
      assert format("{$amount :currency}", %{"amount" => money}) == "$42.50"
    end

    test "derives currency from Money struct with EUR" do
      money = Money.new(:EUR, "100.00")
      assert format("{$amount :currency}", %{"amount" => money}) == "€100.00"
    end

    test "explicit currency option overrides Money struct currency" do
      money = Money.new(:USD, "42.50")
      assert format("{$amount :currency currency=EUR}", %{"amount" => money}) == "€42.50"
    end

    test "Money struct with format_options applies them" do
      money = Money.new(:USD, "42.50", currency_symbol: :iso)
      result = format("{$amount :currency}", %{"amount" => money})
      assert result =~ "USD"
      assert result =~ "42.50"
    end

    test "MF2 options override Money format_options" do
      money = Money.new(:USD, "42.50", currency_symbol: :iso)
      # currencyDisplay=narrowSymbol should override the :iso from format_options
      result = format("{$amount :currency currencyDisplay=narrowSymbol}", %{"amount" => money})
      assert result == "$42.50"
    end

    test "Money struct with accounting sign" do
      money = Money.new(:USD, "-42.50")

      assert format(
               "{$amount :currency currencySign=accounting}",
               %{"amount" => money}
             ) == "($42.50)"
    end

    test "Money struct with currencyDisplay=code" do
      money = Money.new(:USD, "42.50")
      result = format("{$amount :currency currencyDisplay=code}", %{"amount" => money})
      assert result == "USD\u00A042.50"
    end

    test "Money struct in a sentence" do
      money = Money.new(:USD, "9.99")

      assert format("The price is {$price :currency}.", %{"price" => money}) ==
               "The price is $9.99."
    end
  end
end
