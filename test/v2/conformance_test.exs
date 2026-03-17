defmodule Cldr.Message.V2.ConformanceTest do
  use ExUnit.Case, async: true

  alias Cldr.Message.V2.Parser

  describe "syntax.json — valid messages should parse" do
    for {test_case, index} <-
          Path.join([__DIR__, "..", "fixtures", "mf2", "syntax.json"])
          |> File.read!()
          |> Jason.decode!()
          |> Map.get("tests", [])
          |> Enum.with_index() do
      src = test_case["src"]

      if src != nil do
        @tag index: index
        test "[#{index}] #{String.slice(test_case["description"] || src || "", 0..80)}" do
          src = unquote(src)
          result = Parser.parse(src)

          assert match?({:ok, _}, result),
                 "Expected successful parse of #{inspect(src)}, got: #{inspect(result)}"
        end
      end
    end
  end

  describe "syntax-errors.json — invalid messages should fail to parse" do
    for {test_case, index} <-
          Path.join([__DIR__, "..", "fixtures", "mf2", "syntax-errors.json"])
          |> File.read!()
          |> Jason.decode!()
          |> Map.get("tests", [])
          |> Enum.with_index() do
      src = test_case["src"]

      if src != nil do
        @tag index: index
        test "[#{index}] should reject: #{String.slice(src || "", 0..40)}" do
          src = unquote(src)
          result = Parser.parse(src)

          assert match?({:error, _}, result),
                 "Expected parse error for #{inspect(src)}, got: #{inspect(result)}"
        end
      end
    end
  end
end
