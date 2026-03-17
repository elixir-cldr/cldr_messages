# MF2 Benchmark: Elixir Interpreter vs ICU NIF
#
# Run with:
#   mix run bench/mf2_bench.exs
#
# Requires:
#   - benchee dependency
#   - NIF compiled (CLDR_MESSAGES_MF2_NIF=true mix compile)

alias Cldr.Message.V2.{Parser, Interpreter, Nif}

unless Nif.available?() do
  IO.puts("ERROR: MF2 NIF is not available. Compile with CLDR_MESSAGES_MF2_NIF=true")
  System.halt(1)
end

IO.puts("MF2 Benchmark: Elixir Interpreter vs ICU NIF\n")

# ── Test messages ─────────────────────────────────────────────

messages = %{
  "simple text" => %{
    src: "Hello, world!",
    args: %{}
  },
  "variable substitution" => %{
    src: "Hello {$name}!",
    args: %{"name" => "World"}
  },
  "number formatting" => %{
    src: "You have {$count :number} messages",
    args: %{"count" => 1234}
  },
  "literal expression" => %{
    src: "{|hello|}",
    args: %{}
  },
  "quoted pattern" => %{
    src: "{{hello world}}",
    args: %{}
  },
  "complex with .input" => %{
    src: ".input {$name :string}\n{{Hello {$name}!}}",
    args: %{"name" => "World"}
  },
  "match selector" => %{
    src: ".input {$count :number}\n.match $count\n1 {{one item}}\n* {{{$count} items}}",
    args: %{"count" => 5}
  },
  "multiple variables" => %{
    src: "{$greeting}, {$name}! You have {$count :number} new messages.",
    args: %{"greeting" => "Hello", "name" => "Alice", "count" => 42}
  },
  "nested declarations" => %{
    src: ".input {$x :number}\n.local $doubled = {$x :number}\n{{{$x} doubled is {$doubled}}}",
    args: %{"x" => 21}
  }
}

# ── Pre-parse for fair comparison ─────────────────────────────

parsed_messages =
  Map.new(messages, fn {name, %{src: src}} ->
    {:ok, parsed} = Parser.parse(src)
    {name, parsed}
  end)

options = [backend: MyApp.Cldr, locale: "en-US"]

# ── Benchmark 1: Parse only ──────────────────────────────────

IO.puts(String.duplicate("─", 60))
IO.puts("Benchmark 1: Parse + Validate")
IO.puts(String.duplicate("─", 60))
IO.puts("")

parse_inputs =
  Map.new(messages, fn {name, %{src: src}} -> {name, src} end)

Benchee.run(
  %{
    "Elixir Parser" => fn src -> Parser.parse(src) end,
    "ICU NIF validate" => fn src -> Nif.validate(src) end
  },
  inputs: parse_inputs,
  time: 3,
  warmup: 1,
  memory_time: 1,
  print: [configuration: false]
)

# ── Benchmark 2: Format (parse + interpret) ──────────────────

IO.puts("")
IO.puts(String.duplicate("─", 60))
IO.puts("Benchmark 2: Full Format (parse + format)")
IO.puts(String.duplicate("─", 60))
IO.puts("")

format_inputs =
  Map.new(messages, fn {name, %{src: src, args: args}} -> {name, {src, args}} end)

Benchee.run(
  %{
    "Elixir (parse + interpret)" => fn {src, args} ->
      {:ok, parsed} = Parser.parse(src)
      Interpreter.format_list(parsed, args, options)
    end,
    "ICU NIF format" => fn {src, args} ->
      Nif.format(src, "en", args)
    end
  },
  inputs: format_inputs,
  time: 3,
  warmup: 1,
  memory_time: 1,
  print: [configuration: false]
)

# ── Benchmark 3: Interpret only (pre-parsed) ────────────────

IO.puts("")
IO.puts(String.duplicate("─", 60))
IO.puts("Benchmark 3: Interpret Only (pre-parsed, Elixir only)")
IO.puts(String.duplicate("─", 60))
IO.puts("")

interpret_inputs =
  Map.new(messages, fn {name, %{args: args}} ->
    {name, {parsed_messages[name], args}}
  end)

Benchee.run(
  %{
    "Elixir interpret (pre-parsed)" => fn {parsed, args} ->
      Interpreter.format_list(parsed, args, options)
    end
  },
  inputs: interpret_inputs,
  time: 3,
  warmup: 1,
  memory_time: 1,
  print: [configuration: false]
)

# ── Benchmark 4: Unified API ────────────────────────────────

IO.puts("")
IO.puts(String.duplicate("─", 60))
IO.puts("Benchmark 4: Cldr.Message.format/3 Unified API")
IO.puts(String.duplicate("─", 60))
IO.puts("")

api_inputs = %{
  "V1 simple" => {"{greeting} world!", [greeting: "Hello"], []},
  "V2 simple" => {"Hello {$name}!", %{"name" => "World"}, [version: :v2]},
  "V2 complex" => {
    ".input {$count :number}\n.match $count\n1 {{one}}\n* {{{$count} items}}",
    %{"count" => 5},
    []
  }
}

Benchee.run(
  %{
    "Cldr.Message.format/3" => fn {msg, bindings, opts} ->
      Cldr.Message.format(msg, bindings, opts)
    end
  },
  inputs: api_inputs,
  time: 3,
  warmup: 1,
  memory_time: 1,
  print: [configuration: false]
)
