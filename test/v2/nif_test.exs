defmodule Cldr.Message.V2.NifTest do
  use ExUnit.Case, async: true

  @moduletag :mf2_nif

  alias Cldr.Message.V2.Nif
  alias Cldr.Message.V2.Parser

  describe "NIF availability" do
    test "NIF is loaded and available" do
      assert Nif.available?()
    end
  end

  # Indices 80-86 of syntax.json are skipped: ICU 77's parser diverges from the
  # ABNF spec on extended Unicode name-start chars (+, -, emoji, etc.) that the
  # spec allows as unquoted literals but ICU doesn't yet accept inside expressions.

  describe "cross-validate: syntax.json valid messages" do
    for {test_case, index} <-
          Path.join([__DIR__, "..", "fixtures", "mf2", "syntax.json"])
          |> File.read!()
          |> Jason.decode!()
          |> Map.get("tests", [])
          |> Enum.with_index() do
      src = test_case["src"]

      if src != nil and index not in [80, 81, 82, 83, 84, 85, 86] do
        @tag index: index
        test "[#{index}] both parser and NIF accept: #{String.slice(src, 0..60)}" do
          src = unquote(src)

          elixir_result = Parser.parse(src)
          nif_result = Nif.validate(src)

          assert match?({:ok, _}, elixir_result),
                 "Elixir parser rejected valid message: #{inspect(src)}"

          assert match?({:ok, _}, nif_result),
                 "ICU NIF rejected valid message: #{inspect(src)}, got: #{inspect(nif_result)}"
        end
      end
    end
  end

  describe "cross-validate: syntax-errors.json invalid messages" do
    for {test_case, index} <-
          Path.join([__DIR__, "..", "fixtures", "mf2", "syntax-errors.json"])
          |> File.read!()
          |> Jason.decode!()
          |> Map.get("tests", [])
          |> Enum.with_index() do
      src = test_case["src"]

      if src != nil do
        @tag index: index
        test "[#{index}] both parser and NIF reject: #{String.slice(src, 0..60)}" do
          src = unquote(src)

          elixir_result = Parser.parse(src)
          nif_result = Nif.validate(src)

          assert match?({:error, _}, elixir_result),
                 "Elixir parser accepted invalid message: #{inspect(src)}"

          assert match?({:error, _}, nif_result),
                 "ICU NIF accepted invalid message: #{inspect(src)}"
        end
      end
    end
  end

  describe "NIF formatting" do
    test "simple variable substitution" do
      assert {:ok, "Hello World!"} =
               Nif.format("Hello {$name}!", "en", %{"name" => "World"})
    end

    test "number formatting" do
      assert {:ok, result} =
               Nif.format("{$count :number}", "en", %{"count" => 1234})

      assert result =~ "1"
    end

    test "match with number selector" do
      msg = ".input {$count :number}\n.match $count\n1 {{one item}}\n* {{{$count} items}}"

      assert {:ok, "one item"} = Nif.format(msg, "en", %{"count" => 1})
      assert {:ok, result} = Nif.format(msg, "en", %{"count" => 5})
      assert result =~ "items"
    end

    test "literal expression" do
      assert {:ok, "hello"} = Nif.format("{|hello|}", "en", %{})
    end

    test "empty message" do
      assert {:ok, ""} = Nif.format("", "en", %{})
    end

    test "quoted pattern" do
      assert {:ok, "hello world"} = Nif.format("{{hello world}}", "en", %{})
    end
  end
end
