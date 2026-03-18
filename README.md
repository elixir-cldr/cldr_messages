# Cldr Messages

![Build status](https://github.com/elixir-cldr/cldr_messages/actions/workflows/ci.yml/badge.svg)
[![Hex.pm](https://img.shields.io/hexpm/v/ex_cldr_messages.svg)](https://hex.pm/packages/ex_cldr_messages)
[![Hex.pm](https://img.shields.io/hexpm/dw/ex_cldr_messages.svg?)](https://hex.pm/packages/ex_cldr_messages)
[![Hex.pm](https://img.shields.io/hexpm/l/ex_cldr_messages.svg)](https://hex.pm/packages/ex_cldr_messages)

## Installation

```elixir
def deps do
  [
    {:ex_cldr_messages, "~> 2.0"}
  ]
end
```

Documentation is at [https://hexdocs.pm/ex_cldr_messages](https://hexdocs.pm/ex_cldr_messages).

## Introduction

`ex_cldr_message` implements [Unicode MessageFormat 2 (MF2)](https://unicode.org/reports/tr35/tr35-messageFormat.html) and the legacy [ICU Message Format](https://unicode-org.github.io/icu/userguide/format_parse/messages) for Elixir, integrated with the [ex_cldr](https://hex.pm/packages/ex_cldr) ecosystem supporting over 700 locales.

MessageFormat 2 is the next generation of ICU message formatting, designed to be more expressive, extensible and easier to work with than the legacy format. It introduces a clearer syntax with explicit declarations, functions, and pattern matching, while maintaining the same goals: enabling translatable, locale-aware messages with built-in support for plurals, gender selection, and formatted values.

Version detection is automatic: messages starting with `.` (`.input`, `.local`, `.match`) or `{{` are treated as MF2; everything else is treated as legacy ICU Message Format (v1). An explicit `:version` option (`:v1` or `:v2`) overrides auto-detection.

## Getting Started

In common with other [ex_cldr](https://hex.pm/packages/ex_cldr)-based libraries, a `Cldr.Message` provider module needs to be configured as part of a [CLDR backend](https://hexdocs.pm/ex_cldr/readme.html#backend-module-configuration) module definition. For example:

```elixir
defmodule MyApp.Cldr do
  use Cldr,
    locales: ["en", "fr", "ja", "he", "th", "ar"],
    default_locale: "en",
    providers: [Cldr.Number, Cldr.DateTime, Cldr.Unit, Cldr.List, Cldr.Calendar, Cldr.Message]
end
```

The provider `Cldr.Number`, `Cldr.List` and `Cldr.Message` are required. All other providers are optional but if configured provide formatting of dates, times, lists and units within messages.

## MessageFormat 2

MF2 messages use declarations (`.input`, `.local`) to bind and transform variables, `{{` quoted patterns `}}` for output, and `.match` for pattern matching on selectors. See the [Syntax and Usage guide](message_format_v2.html) for full details of the syntax, functions and options.

### Simple Messages

A simple MF2 message is wrapped in `{{ }}`:

```elixir
iex> Cldr.Message.format! "{{Hello, world!}}"
"Hello, world!"

iex> Cldr.Message.format! ".input {$name :string}\n{{Hello, {$name}!}}", %{"name" => "Alice"}
"Hello, Alice!"
```

### Number Formatting

MF2 provides `:number`, `:integer`, `:percent` and `:currency` functions:

```elixir
iex> Cldr.Message.format! ".input {$count :number}\n{{You have {$count} items.}}", %{"count" => 1042}
"You have 1,042 items."

iex> Cldr.Message.format! ".input {$pct :percent}\n{{Score: {$pct}}}", %{"pct" => 0.85}
"Score: 85%"
```

### Pattern Matching with `.match`

The `.match` declaration selects a variant based on the value of one or more selectors:

```elixir
iex> Cldr.Message.format! """
...> .input {$count :number}
...> .match {$count :integer}
...> 1 {{You have one item.}}
...> * {{You have {$count} items.}}
...> """, %{"count" => 5}
"You have 5 items."
```

### Declarations

`.input` declares an external variable with an optional formatting function. `.local` binds a new variable from an expression:

```elixir
iex> Cldr.Message.format! """
...> .input {$date :date}
...> .local $greeting = {|Hello|}
...> {{On {$date}, {$greeting}!}}
...> """, %{"date" => ~D[2024-03-15]}
"On Mar 15, 2024, Hello!"
```

### Supported Functions

| Function    | Description                                    |
|-------------|------------------------------------------------|
| `:string`   | String coercion / pass-through                 |
| `:number`   | Locale-aware number formatting                 |
| `:integer`  | Integer formatting (truncates decimals)         |
| `:percent`  | Percentage formatting                          |
| `:currency` | Currency formatting (requires `ex_money`)       |
| `:date`     | Date formatting (requires `ex_cldr_dates_times`)|
| `:time`     | Time formatting (requires `ex_cldr_dates_times`)|
| `:datetime` | DateTime formatting (requires `ex_cldr_dates_times`) |

### Markup

MF2 supports markup elements for structured output:

```elixir
# Open/close markup
".input {$name :string}\n{{Click {#link}here{/link} to greet {$name}.}}"

# Self-closing markup
"{{An image: {#img src=|photo.jpg| /}}}"
```

## Formatting API

The API is the same for both MF2 and legacy messages. Version detection is automatic.

```elixir
# MF2 message (detected by leading `.` or `{{`)
iex> Cldr.Message.format "{{Hello, {$name}!}}", %{"name" => "World"}
{:ok, "Hello, World!"}

# Legacy message (detected by absence of MF2 markers)
iex> Cldr.Message.format "{greeting} to you!", greeting: "Good morning"
{:ok, "Good morning to you!"}

# Bang variant raises on error
iex> Cldr.Message.format! "{{Hello!}}"
"Hello!"

# Explicit version override
iex> Cldr.Message.format "{greeting}", [greeting: "Hi"], version: :v1
{:ok, "Hi"}
```

### Backend Macro Form

For compile-time parsing and optimized runtime performance, import your backend module:

```elixir
defmodule SomeModule do
  import MyApp.Cldr.Message

  def my_function do
    format("this is a string with a param {param}", param: 3)
  end
end
```

## Deviations from ICU MF2

The Elixir MF2 implementation has been validated against the ICU4C reference implementation (via NIF) using the official MF2 test suite. The remaining known deviations are:

### Markup Rendering

The MF2 specification does not prescribe how markup placeholders should appear in formatted string output. Both the Elixir interpreter and the ICU4C reference implementation produce empty string output for markup placeholders in `format-to-string` mode. Markup is structural metadata intended for `format-to-parts` APIs.

### Variable Name Case Sensitivity

Variable names are case sensitive. `$name` and `$Name` are different variables and require separate bindings.

### Unbound Variable Fallback

When a variable is referenced but no binding is provided:

- **ICU4C**: produces a fallback string `{$variableName}`

- **Elixir**: returns `{:error, {Cldr.Message.BindError, reason}}` with details of which variables were unbound

### Number Formatting Options

MF2 number formatting options (`minimumFractionDigits`, `maximumFractionDigits`, `useGrouping`, `numberingSystem`) are mapped to their `ex_cldr_numbers` equivalents. See the [Syntax and Usage guide](message_format_v2.html) for full details on supported options.

### Unicode Normalization (NFC)

The Elixir implementation applies NFC normalization to variable names, literal values, and binding map keys per the MF2 specification. Pre-composed and decomposed Unicode characters (e.g. `U+1E0C` vs `D` + `U+0323`) are treated as equivalent when used as variable names or match keys.

### Unknown / Custom Functions

When a message references a function not known to the implementation:

- **ICU4C**: produces a fallback string like `{$var :unknownFn}` or `{:unknownFn}`

- **Elixir**: produces an empty string

### Exponential Number Literals

Bare number literal expressions (e.g. `{0e1}`, `{1E+2}`) are output as-is in their original string form. When used with the `:number` function, they are parsed and formatted as numbers.

## ICU NIF Backend

`ex_cldr_messages` includes an optional NIF that delegates MF2 formatting to [ICU4C](https://icu.unicode.org/). This provides access to the ICU reference implementation of MessageFormat 2 directly from Elixir.

The NIF is **optional**. When available, it is used by default for MF2 messages. When not available, the pure-Elixir interpreter is used automatically.

### Prerequisites

ICU 75 or later is required. The `unicode/messageformat2.h` header was introduced in ICU 75 — earlier versions do not include MF2 support and the NIF will fail to compile.

* **macOS**: `brew install icu4c` (Homebrew typically ships a recent ICU version)
* **Linux (Debian/Ubuntu)**: `apt-get install libicu-dev`. Note that many Linux distributions still ship ICU versions older than 75 (e.g. Ubuntu 24.04 ships ICU 74). Check your installed version with `icu-config --version` or `pkg-config --modversion icu-i18n`. If your distribution's ICU is too old, you will need to build ICU 75+ from source or use a distribution that packages a newer version.
* **FreeBSD**: `pkg install icu`

The `elixir_make` dependency is already included as an optional dependency.

### Compiling the NIF

The NIF is not compiled by default. Enable it with an environment variable:

```bash
CLDR_MESSAGES_MF2_NIF=true mix compile
```

Or set it permanently in `config/config.exs`:

```elixir
config :ex_cldr_messages, :mf2_nif, true
```

### Formatter Backend Selection

The `:formatter_backend` option on `Cldr.Message.format/3` controls which engine is used for MF2 messages:

| `:formatter_backend` value | Behaviour |
|---|---|
| `:default` (the default) | Uses NIF if available, otherwise pure Elixir |
| `:nif` | Requires NIF; raises `RuntimeError` if unavailable |
| `:elixir` | Always uses pure Elixir, even if NIF is available |

```elixir
# Automatic — NIF when available, Elixir otherwise
Cldr.Message.format("{{Hello, {$name}!}}", %{"name" => "World"})

# Explicit NIF
Cldr.Message.format("{{Hello, {$name}!}}", %{"name" => "World"}, formatter_backend: :nif)

# Explicit Elixir
Cldr.Message.format("{{Hello, {$name}!}}", %{"name" => "World"}, formatter_backend: :elixir)
```

The `:formatter_backend` option only affects MF2 (v2) messages. Legacy v1 messages always use the pure-Elixir interpreter.

### Using the NIF Directly

The NIF module can also be called directly for validation or cross-implementation testing:

```elixir
# Check if the NIF is available
Cldr.Message.V2.Nif.available?()
#=> true

# Validate a message against the ICU parser
Cldr.Message.V2.Nif.validate(".input {$name :string}\n{{Hello, {$name}!}}")
#=> {:ok, ".input {$name :string}\n{{Hello, {$name}!}}"}

# Format a message using ICU4C directly
Cldr.Message.V2.Nif.format(".input {$name :string}\n{{Hello, {$name}!}}", "en", %{"name" => "World"})
#=> {:ok, "Hello, World!"}
```

If the NIF is not compiled, `Cldr.Message.V2.Nif.available?/0` returns `false` and direct calls to `Cldr.Message.V2.Nif.format/3` or `Cldr.Message.V2.Nif.validate/1` will raise `:nif_library_not_loaded`.

## Performance

The following benchmarks compare the pure-Elixir MF2 implementation against the ICU4C NIF across a range of message types. Benchmarks were run using [Benchee](https://hex.pm/packages/benchee) on an Apple Silicon Mac. The benchmark script is at `bench/mf2_bench.exs`.

### Full Format (Parse + Interpret)

This measures the complete pipeline: parsing the message string and producing formatted output.

| Message Type | Elixir (ips) | ICU NIF (ips) | Comparison |
|---|---|---|---|
| Simple text (`Hello, world!`) | 186K | 64K | Elixir 2.9x faster |
| Literal expression (`{|hello|}`) | 119K | 75K | Elixir 1.6x faster |
| Quoted pattern (`{{hello world}}`) | 228K | 69K | Elixir 3.3x faster |
| Variable substitution (`Hello {$name}!`) | 76K | 53K | Elixir 1.4x faster |
| Complex with `.input` declaration | 48K | 44K | Comparable |
| Multiple variables (3 vars + `:number`) | 980 | 17K | NIF 17x faster |
| Number formatting (`:number`) | 990 | 22K | NIF 22x faster |
| Match selector (`.match`) | 960 | 9.5K | NIF 10x faster |
| Nested declarations (`.input` + `.local`) | 480 | 12K | NIF 26x faster |

### Parse Only

Parsing/validation without formatting. The Elixir parser (NimbleParsec) is consistently faster than the ICU NIF for pure parsing:

| Message Type | Elixir Parser (ips) | ICU NIF Validate (ips) | Comparison |
|---|---|---|---|
| Simple text | 220K | 72K | Elixir 3.1x faster |
| Quoted pattern | 299K | 76K | Elixir 3.9x faster |
| Variable substitution | 107K | 75K | Elixir 1.4x faster |
| Complex with `.input` | 71K | 57K | Elixir 1.2x faster |
| Match selector | 39K | 26K | Elixir 1.5x faster |

### Interpret Only (Pre-parsed AST)

When the message has already been parsed (e.g. at compile time or cached), the Elixir interpreter operates on the AST directly:

| Message Type | Elixir (ips) |
|---|---|
| Simple text | 1,620K |
| Quoted pattern | 1,270K |
| Literal expression | 887K |
| Variable substitution | 474K |
| Complex with `.input` | 308K |
| Number formatting | 1,020 |
| Match selector | 974 |

### Summary

* **Simple messages** (text, literals, variable substitution): The pure-Elixir implementation is 1.4-3.9x faster than the NIF due to the overhead of crossing the NIF boundary for small workloads.

* **Number formatting**: ICU4C is 10-26x faster because number formatting calls through the CLDR/Elixir number formatting stack, which involves significant BEAM-side work. The ICU NIF handles this entirely in C++.

* **Pre-parsed messages**: When parsing is done at compile time, the Elixir interpreter achieves millions of iterations per second for simple messages, making the parse overhead negligible for production use.

* **Memory**: The NIF uses far less BEAM-side memory per operation. The Elixir implementation's memory usage is typical for a pure-Elixir implementation and is not a concern for normal workloads.

## Gettext Integration

As of [Gettext 0.19](https://hex.pm/packages/gettext/0.19.0), `Gettext` supports user-defined [interpolation modules](https://hexdocs.pm/gettext/Gettext.html#module-backend-configuration). This makes it easy to combine ICU message formats with the broad `gettext` ecosystem and the inbuilt support for `gettext` in [Phoenix](https://hex.pm/packages/phoenix).

Two interpolation modules are available:

| Module | Description |
|---|---|
| `Cldr.Gettext.Interpolation` | Legacy v1 messages only |
| `Cldr.Gettext.Interpolation.V2` | Both v1 and v2 messages with auto-detection. Compiles as V2 first, falls back to V1. |

For new projects, `Cldr.Gettext.Interpolation.V2` is recommended as it handles both formats transparently.

### Defining a Gettext Interpolation Module

Any [ex_cldr](https://hex.pm/packages/ex_cldr) [backend module](https://hexdocs.pm/ex_cldr/readme.html#backend-module-configuration) that has a `Cldr.Message` provider configured can be used as an interpolation module. Here is an example using the V2 interpolation module:
```elixir
defmodule MyApp.Cldr do
  use Cldr,
    locales: ["en", "fr", "ja", "he", "th", "ar"],
    default_locale: "en",
    providers: [Cldr.Number, Cldr.DateTime, Cldr.Unit, Cldr.List, Cldr.Calendar, Cldr.Message],
    gettext: MyApp.Gettext,
    message_formats: %{
      USD: [format: :long]
    }
end

defmodule MyApp.Gettext.Interpolation do
  use Cldr.Gettext.Interpolation.V2, cldr_backend: MyApp.Cldr
end

defmodule MyApp.Gettext do
  use Gettext.Backend, otp_app: :my_app, interpolation: MyApp.Gettext.Interpolation
end

defmodule MyApp do
  use Gettext, backend: MyApp.Gettext

  def my_module do
    # V1 messages work as before
    gettext("Created at {created_at}", created_at: ~D[2022-01-22])

    # V2 messages are auto-detected
    gettext("{{Hello, {$name}!}}", %{"name" => "World"})
  end
end
```

Now you can proceed to use `Gettext` in the normal manner, most typically with the `gettext/3` macro. Both v1 and v2 messages can coexist in the same `.POT` files.

## Message Format 1 (Supported but Deprecated)

The legacy ICU Message Format (v1) remains fully supported but is considered deprecated in favour of MF2. Existing v1 messages will continue to work without changes and are auto-detected by the unified API.

### Legacy Format Overview

Legacy ICU message formats are strings with embedded formatting directives inserted between `{}`:

```elixir
# Simple variable substitution
"My name is {name}"

# Date formatting and plurals
"On {taken_date, date, short} {name} took {num_photos, plural,
  =0 {no photos.}
  =1 {one photo.}
  other {# photos.}}"

# Gender selection with nested plurals
"{gender_of_host, select,
  female {
    {num_guests, plural, offset: 1
      =0 {{host} does not give a party.}
      =1 {{host} invites {guest} to her party.}
      =2 {{host} invites {guest} and one other person to her party.}
      other {{host} invites {guest} and # other people to her party.}}}
  male {
    {num_guests, plural, offset: 1
      =0 {{host} does not give a party.}
      =1 {{host} invites {guest} to his party.}
      =2 {{host} invites {guest} and one other person to his party.}
      other {{host} invites {guest} and # other people to his party.}}}
  other {
    {num_guests, plural, offset: 1
      =0 {{host} does not give a party.}
      =1 {{host} invites {guest} to their party.}
      =2 {{host} invites {guest} and one other person to their party.}
      other {{host} invites {guest} and # other people to their party.}}}
}"
```

### MF1 Format Examples

```elixir
iex> Cldr.Message.format! "My name is {name}", name: "Kip"
"My name is Kip"

iex> Cldr.Message.format! "On {taken_date, date, short} {name} took {num_photos, plural,
       =0 {no photos.}
       =1 {one photo.}
       other {# photos.}}", taken_date: Date.utc_today, name: "Kip", num_photos: 10
"On 8/26/19 Kip took 10 photos."
```

Further information on the legacy ICU message format is [here](message_format_v1.html).
