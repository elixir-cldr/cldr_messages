defmodule Cldr.Message.V2.FormatErrorTest do
  use ExUnit.Case, async: true

  @opts [version: :v2, formatter_backend: :elixir]

  describe "invalid bindings for :number" do
    test "non-numeric string returns error" do
      assert {:error, {Cldr.Message.FormatError, reason}} =
               Cldr.Message.format("{$x :number}", %{"x" => "hello"}, @opts)

      assert reason =~ "cannot parse"
      assert reason =~ "as a number"
    end

    test "list returns error" do
      assert {:error, {Cldr.Message.FormatError, reason}} =
               Cldr.Message.format("{$x :number}", %{"x" => [1, 2, 3]}, @opts)

      assert reason =~ "cannot format"
      assert reason =~ "as a number"
    end

    test "Cldr.Unit struct returns error" do
      unit = Cldr.Unit.new!(3, :kilometer)

      assert {:error, {Cldr.Message.FormatError, reason}} =
               Cldr.Message.format("{$x :number}", %{"x" => unit}, @opts)

      assert reason =~ "cannot format"
      assert reason =~ "as a number"
    end

    test "Money struct returns error" do
      money = Money.new(:USD, 100)

      assert {:error, {Cldr.Message.FormatError, reason}} =
               Cldr.Message.format("{$x :number}", %{"x" => money}, @opts)

      assert reason =~ "cannot format"
      assert reason =~ "as a number"
    end

    test "map returns error" do
      assert {:error, {Cldr.Message.FormatError, reason}} =
               Cldr.Message.format("{$x :number}", %{"x" => %{a: 1}}, @opts)

      assert reason =~ "cannot format"
      assert reason =~ "as a number"
    end

    test "boolean returns error" do
      assert {:error, {Cldr.Message.FormatError, reason}} =
               Cldr.Message.format("{$x :number}", %{"x" => true}, @opts)

      assert reason =~ "cannot format"
      assert reason =~ "as a number"
    end
  end

  describe "invalid bindings for :integer" do
    test "non-numeric string returns error" do
      assert {:error, {Cldr.Message.FormatError, reason}} =
               Cldr.Message.format("{$x :integer}", %{"x" => "abc"}, @opts)

      assert reason =~ "cannot parse"
      assert reason =~ "as a number"
    end

    test "Cldr.Unit struct returns error" do
      unit = Cldr.Unit.new!(3, :kilometer)

      assert {:error, {Cldr.Message.FormatError, reason}} =
               Cldr.Message.format("{$x :integer}", %{"x" => unit}, @opts)

      assert reason =~ "cannot format"
      assert reason =~ "as a number"
    end

    test "Money struct returns error" do
      money = Money.new(:USD, 100)

      assert {:error, {Cldr.Message.FormatError, reason}} =
               Cldr.Message.format("{$x :integer}", %{"x" => money}, @opts)

      assert reason =~ "cannot format"
      assert reason =~ "as a number"
    end
  end

  describe "invalid bindings for :percent" do
    test "non-numeric string returns error" do
      assert {:error, {Cldr.Message.FormatError, reason}} =
               Cldr.Message.format("{$x :percent}", %{"x" => "xyz"}, @opts)

      assert reason =~ "cannot parse"
      assert reason =~ "as a number"
    end

    test "Date struct returns error" do
      assert {:error, {Cldr.Message.FormatError, reason}} =
               Cldr.Message.format("{$x :percent}", %{"x" => ~D[2024-01-01]}, @opts)

      assert reason =~ "cannot format"
      assert reason =~ "as a number"
    end
  end

  describe "invalid bindings for :currency" do
    test "non-numeric string returns error" do
      assert {:error, {Cldr.Message.FormatError, reason}} =
               Cldr.Message.format("{$x :currency currency=USD}", %{"x" => "abc"}, @opts)

      assert reason =~ "as a number"
    end

    test "Cldr.Unit struct returns error" do
      unit = Cldr.Unit.new!(3, :kilometer)

      assert {:error, {Cldr.Message.FormatError, reason}} =
               Cldr.Message.format("{$x :currency currency=USD}", %{"x" => unit}, @opts)

      assert reason =~ "cannot format"
      assert reason =~ "as a number"
    end

    test "Date struct returns error" do
      assert {:error, {Cldr.Message.FormatError, reason}} =
               Cldr.Message.format("{$x :currency currency=USD}", %{"x" => ~D[2024-01-01]}, @opts)

      assert reason =~ "cannot format"
      assert reason =~ "as a number"
    end
  end

  describe "invalid bindings for :date" do
    test "number returns error" do
      assert {:error, {Cldr.Message.FormatError, reason}} =
               Cldr.Message.format("{$x :date}", %{"x" => 42}, @opts)

      assert reason =~ "cannot format"
      assert reason =~ "as a date"
    end

    test "unparseable string returns error" do
      assert {:error, {Cldr.Message.FormatError, reason}} =
               Cldr.Message.format("{$x :date}", %{"x" => "not-a-date"}, @opts)

      assert reason =~ "cannot parse"
      assert reason =~ "as a date"
    end

    test "Money struct returns error" do
      money = Money.new(:USD, 100)

      assert {:error, {Cldr.Message.FormatError, reason}} =
               Cldr.Message.format("{$x :date}", %{"x" => money}, @opts)

      assert reason =~ "cannot format"
      assert reason =~ "as a date"
    end

    test "Cldr.Unit struct returns error" do
      unit = Cldr.Unit.new!(3, :kilometer)

      assert {:error, {Cldr.Message.FormatError, reason}} =
               Cldr.Message.format("{$x :date}", %{"x" => unit}, @opts)

      assert reason =~ "cannot format"
      assert reason =~ "as a date"
    end

    test "list returns error" do
      assert {:error, {Cldr.Message.FormatError, reason}} =
               Cldr.Message.format("{$x :date}", %{"x" => [2024, 1, 1]}, @opts)

      assert reason =~ "cannot format"
      assert reason =~ "as a date"
    end
  end

  describe "invalid bindings for :time" do
    test "number returns error" do
      assert {:error, {Cldr.Message.FormatError, reason}} =
               Cldr.Message.format("{$x :time}", %{"x" => 42}, @opts)

      assert reason =~ "cannot format"
      assert reason =~ "as a datetime"
    end

    test "unparseable string returns error" do
      assert {:error, {Cldr.Message.FormatError, reason}} =
               Cldr.Message.format("{$x :time}", %{"x" => "not-a-time"}, @opts)

      assert reason =~ "cannot parse"
      assert reason =~ "as a datetime"
    end

    test "Money struct returns error" do
      money = Money.new(:USD, 100)

      assert {:error, {Cldr.Message.FormatError, reason}} =
               Cldr.Message.format("{$x :time}", %{"x" => money}, @opts)

      assert reason =~ "cannot format"
      assert reason =~ "as a datetime"
    end
  end

  describe "invalid bindings for :datetime" do
    test "number returns error" do
      assert {:error, {Cldr.Message.FormatError, reason}} =
               Cldr.Message.format("{$x :datetime}", %{"x" => 42}, @opts)

      assert reason =~ "cannot format"
      assert reason =~ "as a datetime"
    end

    test "unparseable string returns error" do
      assert {:error, {Cldr.Message.FormatError, reason}} =
               Cldr.Message.format("{$x :datetime}", %{"x" => "garbage"}, @opts)

      assert reason =~ "cannot parse"
      assert reason =~ "as a datetime"
    end

    test "list returns error" do
      assert {:error, {Cldr.Message.FormatError, reason}} =
               Cldr.Message.format("{$x :datetime}", %{"x" => [1, 2, 3]}, @opts)

      assert reason =~ "cannot format"
      assert reason =~ "as a datetime"
    end
  end

  describe "invalid bindings for :unit" do
    test "Money struct returns error" do
      money = Money.new(:USD, 100)

      assert {:error, {Cldr.Message.FormatError, reason}} =
               Cldr.Message.format("{$x :unit unit=kilometer}", %{"x" => money}, @opts)

      assert reason =~ "cannot format"
      assert reason =~ "as a number"
    end

    test "Date struct returns error" do
      assert {:error, {Cldr.Message.FormatError, reason}} =
               Cldr.Message.format("{$x :unit unit=kilometer}", %{"x" => ~D[2024-01-01]}, @opts)

      assert reason =~ "cannot format"
      assert reason =~ "as a number"
    end

    test "missing unit option returns error" do
      assert {:error, {Cldr.Message.FormatError, reason}} =
               Cldr.Message.format("{$x :unit}", %{"x" => 5}, @opts)

      assert reason =~ "requires a `unit` option"
    end

    test "non-numeric string returns error" do
      assert {:error, {Cldr.Message.FormatError, reason}} =
               Cldr.Message.format("{$x :unit unit=kilometer}", %{"x" => "abc"}, @opts)

      assert reason =~ "as a number"
    end
  end

  describe "invalid bindings in .input declarations" do
    test "returns error for invalid type in .input" do
      message = ~S"""
      .input {$count :number}
      .match $count
        1 {{one item}}
        * {{{$count} items}}
      """

      assert {:error, {Cldr.Message.FormatError, reason}} =
               Cldr.Message.format(message, %{"count" => "hello"}, @opts)

      assert reason =~ "as a number"
    end
  end

  describe "cross-type mismatches" do
    test "Date to :number returns error" do
      assert {:error, {Cldr.Message.FormatError, reason}} =
               Cldr.Message.format("{$x :number}", %{"x" => ~D[2024-01-01]}, @opts)

      assert reason =~ "cannot format"
      assert reason =~ "as a number"
    end

    test "number to :currency returns error" do
      assert {:error, {Cldr.Message.FormatError, _}} =
               Cldr.Message.format("{$x :currency currency=USD}", %{"x" => [1]}, @opts)
    end

    test "Cldr.Unit to :date returns error" do
      unit = Cldr.Unit.new!(3, :kilometer)

      assert {:error, {Cldr.Message.FormatError, reason}} =
               Cldr.Message.format("{$x :date}", %{"x" => unit}, @opts)

      assert reason =~ "cannot format"
      assert reason =~ "as a date"
    end

    test "Money to :datetime returns error" do
      money = Money.new(:USD, 100)

      assert {:error, {Cldr.Message.FormatError, reason}} =
               Cldr.Message.format("{$x :datetime}", %{"x" => money}, @opts)

      assert reason =~ "cannot format"
      assert reason =~ "as a datetime"
    end

    test "Money to :time returns error" do
      money = Money.new(:USD, 100)

      assert {:error, {Cldr.Message.FormatError, reason}} =
               Cldr.Message.format("{$x :time}", %{"x" => money}, @opts)

      assert reason =~ "cannot format"
      assert reason =~ "as a datetime"
    end
  end
end
