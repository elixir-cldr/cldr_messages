# MessageFormat 2 (MF2) Syntax Reference

This document is a developer-oriented reference for [Unicode MessageFormat 2](https://unicode.org/reports/tr35/tr35-messageFormat.html) (MF2) syntax as implemented in `ex_cldr_messages`. It covers the grammar, semantics, and built-in functions available when writing MF2 messages.

MF2 is the successor to the legacy ICU Message Format. It provides a clearer, more extensible syntax with explicit declarations, a function registry, pattern matching, and markup support.

## Message Structure

Every MF2 message is either a **simple message** or a **complex message**.

### Simple Messages

A simple message is plain text with optional placeholders. It cannot start with `.` or `{{`.

```
Hello, world!
Hello, {$name}!
Today is {$date :date style=medium}.
```

Simple messages are the most common form. Text is literal; placeholders are enclosed in `{ }`.

### Complex Messages

A complex message starts with declarations (`.input`, `.local`) or a body keyword (`.match`, `{{`). The output pattern is always wrapped in `{{ }}` (a quoted pattern) or defined by `.match` variants.

```
.input {$name :string}
{{Hello, {$name}!}}
```

```
.input {$count :number}
.local $greeting = {|Welcome|}
.match $count
1 {{You have one item, {$greeting}.}}
* {{You have {$count} items, {$greeting}.}}
```

## Variables

Variables are prefixed with `$` and refer to values passed as bindings at format time.

```
{$userName}
{$count :number}
```

Variable names follow MF2 naming rules: they start with a letter, `_`, or `+`, followed by letters, digits, `-`, or `.`.

When formatting, bindings can be provided as a map with string keys or atom keys:

```elixir
iex> Cldr.Message.format!("{{Hello, {$name}!}}", %{"name" => "Alice"})
"Hello, Alice!"

iex> Cldr.Message.format!("{{Hello, {$name}!}}", [name: "Alice"])
"Hello, Alice!"
```

## Literals

### Quoted Literals

Quoted literals are enclosed in `| |` and can contain any text. Use `\\` to escape `\` and `\|` to escape `|` within quoted literals.

```
{|Hello, world!|}
{|special chars: \| and \\|}
```

### Unquoted Literals

Unquoted literals are bare names or number literals used directly.

```
{hello}
{42}
{3.14}
```

### Number Literals

Number literals follow the pattern `[-] digits [. digits] [e [+-] digits]`:

```
42
-7
3.14
1.5e3
```

## Expressions

An expression is enclosed in `{ }` and consists of an optional operand, an optional function annotation, and optional attributes.

```
{$variable}                        Variable reference
{$count :number}                   Variable with function
{|literal text| :string}           Literal with function
{:datetime}                        Function-only (no operand)
{$x :number minimumFractionDigits=2}  Function with options
{$name @translatable}              Variable with attribute
```

### General Form

```
{ [operand] [:function [options...]] [@attribute...] }
```

Where:
- **operand** is a variable (`$name`), quoted literal (`|text|`), or number literal (`42`)
- **function** is `:functionName` optionally followed by space-separated `key=value` options
- **attributes** are `@name` or `@name=value` metadata annotations

## Functions

Functions transform or format values. They are invoked with `:functionName` syntax inside an expression.

### `:string`

String coercion. Passes the value through as a string.

```
{$name :string}
```

### `:number`

Locale-aware number formatting using `Cldr.Number`.

```
{$count :number}
{$price :number minimumFractionDigits=2}
```

**Options**: `minimumFractionDigits`, `maximumFractionDigits`, `useGrouping`, `style` and other CLDR number formatting options.

### `:integer`

Formats a number as an integer (truncates any decimal part).

```
{$count :integer}
```

### `:percent`

Formats a number as a percentage.

```
{$ratio :percent}
```

A value of `0.85` formats as `85%` (locale-dependent).

### `:currency`

Formats a number as a currency amount.

```
{$amount :currency currency=USD}
{$amount :currency currency=EUR currencyDisplay=narrowSymbol}
{$amount :currency currency=USD currencySign=accounting}
```

| Option | Values | Description |
|--------|--------|-------------|
| `currency` | ISO 4217 code (e.g., `USD`, `EUR`) | The currency to format with (required) |
| `currencyDisplay` | `symbol` (default), `narrowSymbol`, `code` | How to display the currency identifier |
| `currencySign` | `standard` (default), `accounting` | `accounting` uses parentheses for negative values |

**Note:** `currencyDisplay=name` is not currently supported.

#### Money struct bindings

When the bound value is a `Money.t` struct (from the `ex_money` package), the currency, amount, and formatting options are derived automatically from the struct:

* The `currency` is taken from the struct's `:currency` field unless an explicit `currency` option is provided in the message.

* The numeric amount is taken from the struct's `:amount` field.

* Any `:format_options` stored on the struct (e.g., `currency_symbol: :iso`) are applied as base formatting options. Options specified in the MF2 message (e.g., `currencyDisplay`, `currencySign`) take precedence over the struct's format options.

This means a `Money.t` value can be formatted without specifying a `currency` option:

```
{$price :currency}
```

### `:unit`

Formats a number with a measurement unit. Requires the `ex_cldr_units` package.

```
{$distance :unit unit=kilometer}
{$weight :unit unit=kilogram unitDisplay=short}
{$temp :unit unit=fahrenheit unitDisplay=narrow}
```

| Option | Values | Description |
|--------|--------|-------------|
| `unit` | CLDR unit identifier (e.g., `kilometer`, `kilogram`) | The unit to format with (required) |
| `unitDisplay` | `long`, `short`, `narrow` | How to display the unit name (default: `long`) |

#### Cldr.Unit struct bindings

When the bound value is a `Cldr.Unit.t` struct, the unit and value are derived automatically from the struct. Any `:format_options` stored on the struct are automatically merged by `Cldr.Unit.to_string/2`.

* The `unit` is taken from the struct's `:unit` field unless an explicit `unit` option is provided in the message.

* The numeric value is taken from the struct's `:value` field.

This means a `Cldr.Unit.t` value can be formatted without specifying a `unit` option:

```
{$distance :unit}
```

### `:date`

Formats a date value. Requires the `ex_cldr_dates_times` package. Accepts ISO 8601 string literals (e.g., `|2006-01-02|`), `Date`, `NaiveDateTime`, or `DateTime` structs.

```
{$when :date}
{$when :date style=short}
{|2006-01-02| :date length=long}
```

| Option | Values | Description |
|--------|--------|-------------|
| `style` | `short`, `medium`, `long`, `full` | Date format style (default: `medium`) |
| `length` | `short`, `medium`, `long`, `full` | Alias for `style` |

### `:time`

Formats a time value. Requires the `ex_cldr_dates_times` package. Accepts ISO 8601 datetime string literals (e.g., `|2006-01-02T15:04:06|`), `NaiveDateTime`, or `DateTime` structs.

```
{$when :time}
{$when :time style=short}
{|2006-01-02T15:04:06| :time precision=second}
```

| Option | Values | Description |
|--------|--------|-------------|
| `style` | `short`, `medium`, `long`, `full` | Time format style (default: `medium`) |
| `precision` | `second`, `minute` | Time precision (`second` maps to `medium`, `minute` maps to `short`) |

### `:datetime`

Formats a datetime value. Requires the `ex_cldr_dates_times` package. Accepts ISO 8601 string literals (e.g., `|2006-01-02T15:04:06|`), `NaiveDateTime`, `DateTime`, or `Date` structs.

```
{$when :datetime}
{$when :datetime style=long}
{$when :datetime dateStyle=long timeStyle=short}
{|2006-01-02T15:04:06| :datetime dateLength=long timePrecision=second}
```

| Option | Values | Description |
|--------|--------|-------------|
| `style` | `short`, `medium`, `long`, `full` | Sets both date and time format style (default: `medium`) |
| `dateStyle` | `short`, `medium`, `long`, `full` | Date portion format style |
| `dateLength` | `short`, `medium`, `long`, `full` | Alias for `dateStyle` |
| `timeStyle` | `short`, `medium`, `long`, `full` | Time portion format style |
| `timePrecision` | `second`, `minute` | Time precision (`second` maps to `medium`, `minute` maps to `short`) |

When `dateStyle`/`timeStyle` are used independently, the other defaults to the locale's `:medium` format.

## Function Options

Function options are `key=value` pairs separated by whitespace after the function name. Values can be quoted literals, unquoted literals, number literals, or variable references.

```
{$n :number minimumFractionDigits=2}
{$n :number style=|percent|}
{$n :number minimumFractionDigits=$precision}
```

## Declarations

Declarations appear at the start of a complex message, before the body. They bind or annotate variables.

### `.input`

Declares an external variable and optionally applies a function to it. The variable must be provided in the bindings at format time.

```
.input {$count :number}
```

This declares that `$count` is expected as input and should be formatted using `:number`. Subsequent references to `$count` in the message body will use the formatted value.

### `.local`

Binds a new local variable to an expression. The right-hand side can reference other variables or use literals.

```
.local $formatted_name = {$name :string}
.local $greeting = {|Hello|}
.local $doubled = {$count :number minimumFractionDigits=2}
```

Local variables are available in the message body and in subsequent declarations.

## Quoted Patterns

The output of a complex message is a quoted pattern: text and placeholders wrapped in `{{ }}`.

```
.input {$name :string}
{{Hello, {$name}!}}
```

Quoted patterns can contain:

* Plain text
* Expressions (`{$var}`, `{$var :func}`, `{|literal|}`)
* Markup elements (`{#tag}`, `{/tag}`, `{#tag /}`)
* Escape sequences (`\\`, `\{`, `\}`, `\|`)

## Pattern Matching with `.match`

The `.match` statement selects one of several variant patterns based on the runtime value of one or more selector expressions.

### Single Selector

```
.input {$count :number}
.match $count
  0 {{No items.}}
  1 {{One item.}}
  * {{You have {$count} items.}}
```

### Multiple Selectors

```
.input {$gender :string}
.input {$count :integer}
.match $gender $count
  male 1 {{He has one item.}}
  female 1 {{She has one item.}}
  * 1 {{They have one item.}}
  male * {{He has {$count} items.}}
  female * {{She has {$count} items.}}
  * * {{They have {$count} items.}}
```

### Variant Keys

Each variant has one key per selector. Keys can be:

* **Literal keys**: match when the selector value equals the literal (e.g., `0`, `1`, `|male|`, `female`)

* **Catchall `*`**: matches any value (lowest priority)

### Matching Rules

1. All keys in a variant must match their corresponding selector values
2. Literal keys are matched by string or numeric equality
3. Variants are sorted by specificity: fewer `*` keys = more specific
4. The most specific matching variant is selected
5. If no variant matches, the result is an error

## Markup

MF2 supports markup elements for structured output. Markup nodes are parsed but rendered as empty strings in the formatted output, consistent with the ICU4C reference implementation. The MF2 specification does not mandate a particular string output for markup.

### Open and Close Tags

```elixir
iex> Cldr.Message.format!("{{Click {#link}here{/link} to continue.}}", %{})
"Click here to continue."
```

### Self-Closing Tags

```elixir
iex> Cldr.Message.format!("{{An image: {#img src=|photo.jpg| /}}}", %{})
"An image: "
```

### Markup with Options and Attributes

```
{#button type=|submit| @translatable}Click me{/button}
```

Markup elements accept the same option (`key=value`) and attribute (`@name`) syntax as expressions.

## Escape Sequences

Within pattern text (inside `{{ }}`), the following escape sequences are recognized:

| Sequence | Produces |
|----------|----------|
| `\\`     | `\`      |
| `\{`     | `{`      |
| `\}`     | `}`      |

Within quoted literals (inside `| |`):

| Sequence | Produces |
|----------|----------|
| `\\`     | `\`      |
| `\|`     | `\|`     |

## Whitespace and BiDi

MF2 supports Unicode bidirectional control characters within the syntax in specific positions (between declarations, around expressions). The following BiDi characters are recognized:

- U+061C (Arabic Letter Mark)
- U+200E (Left-to-Right Mark)
- U+200F (Right-to-Left Mark)
- U+2066-2069 (Isolate controls)

The ideographic space (U+3000) is treated as whitespace.

## Attributes

Attributes provide metadata annotations on expressions and markup. They do not affect formatting output but can be used by tooling (e.g., translation tools, linters).

```
{$name :string @translatable}
{$count :number @source=|database|}
```

## Complete Examples

All examples below use the `en-US` locale (the default) and have been validated against the Elixir formatter.

### Simple Greeting

```elixir
iex> Cldr.Message.format!("{{Hello, {$name}!}}", %{"name" => "World"})
"Hello, World!"
```

### Simple Message (no `{{ }}` wrapper)

```elixir
iex> Cldr.Message.format!("Hello, {$name}!", %{"name" => "World"})
"Hello, World!"
```

### Number Formatting

```elixir
iex> Cldr.Message.format!(~S"""
...> .input {$count :number}
...> {{You have {$count} items in your cart.}}
...> """, %{"count" => 1234})
"You have 1,234 items in your cart."
```

### Number Options

```elixir
iex> Cldr.Message.format!("{{{$n :number minimumFractionDigits=2}}}", %{"n" => 42})
"42.00"

iex> Cldr.Message.format!("{{{$n :number maximumFractionDigits=2}}}", %{"n" => 3.14159})
"3.14"

iex> Cldr.Message.format!("{{{$n :number useGrouping=never}}}", %{"n" => 12345})
"12345"
```

### Integer Formatting

```elixir
iex> Cldr.Message.format!("{{{$n :integer}}}", %{"n" => 4.7})
"4"
```

### Percent Formatting

```elixir
iex> Cldr.Message.format!("{{{$ratio :percent}}}", %{"ratio" => 0.85})
"85%"
```

### Date Formatting

```elixir
iex> Cldr.Message.format!("{|2006-01-02| :date}", %{})
"Jan 2, 2006"

iex> Cldr.Message.format!("{|2006-01-02| :date length=long}", %{})
"January 2, 2006"

iex> Cldr.Message.format!("{|2006-01-02| :date style=short}", %{})
"1/2/06"
```

### Time Formatting

```elixir
iex> Cldr.Message.format!("{|2006-01-02T15:04:06| :time}", %{})
"3:04:06 PM"
```

### Datetime Formatting

```elixir
iex> Cldr.Message.format!("{|2006-01-02T15:04:06| :datetime}", %{})
"Jan 2, 2006, 3:04:06 PM"

iex> Cldr.Message.format!(
...>   "{|2006-01-02T15:04:06| :datetime dateStyle=long timeStyle=short}",
...>   %{}
...> )
"January 2, 2006, 3:04 PM"
```

### Plural Selection

```elixir
iex> Cldr.Message.format!(~S"""
...> .input {$count :number}
...> .match $count
...>   0 {{Your cart is empty.}}
...>   1 {{You have one item in your cart.}}
...>   * {{You have {$count} items in your cart.}}
...> """, %{"count" => 3})
"You have 3 items in your cart."
```

### Local Variable Binding

```elixir
iex> Cldr.Message.format!(~S"""
...> .input {$first :string}
...> .input {$last :string}
...> .local $greeting = {|Welcome|}
...> {{Dear {$first} {$last}, {$greeting}!}}
...> """, %{"first" => "Jane", "last" => "Doe"})
"Dear Jane Doe, Welcome!"
```

### Gender and Plural Selection

```elixir
iex> Cldr.Message.format!(~S"""
...> .input {$gender :string}
...> .input {$count :integer}
...> .match $gender $count
...>   male 1 {{He bought one item.}}
...>   female 1 {{She bought one item.}}
...>   * 1 {{They bought one item.}}
...>   male * {{He bought {$count} items.}}
...>   female * {{She bought {$count} items.}}
...>   * * {{They bought {$count} items.}}
...> """, %{"gender" => "female", "count" => 3})
"She bought 3 items."
```

## Specification Compliance

The `ex_cldr_messages` MF2 implementation targets the [Unicode MessageFormat 2.0 specification](https://unicode.org/reports/tr35/tr35-messageFormat.html) (part of CLDR Technical Standard #35).

### Compliance Summary

| Area | Status |
|------|--------|
| Simple messages | Fully supported |
| Complex messages (declarations + quoted pattern) | Fully supported |
| `.input` declarations | Fully supported |
| `.local` declarations | Fully supported |
| `.match` with single and multiple selectors | Fully supported |
| Variant matching with literal keys and `*` catchall | Fully supported |
| Quoted and unquoted literals | Fully supported |
| Number literals (integer, decimal, scientific) | Fully supported |
| Variables with string and atom key lookup | Fully supported |
| Function annotations (`:functionName`) | Fully supported |
| Function options (`key=value`) | Fully supported |
| Attributes (`@name`, `@name=value`) | Parsed; not used in formatting |
| Markup (open, close, self-closing) | Parsed; rendered as empty strings (per ICU4C) |
| Escape sequences | Fully supported |
| BiDi controls and ideographic space | Fully supported |
| Namespaced identifiers (`ns:name`) | Parsed; not semantically interpreted |
| NFC normalization of output | Not implemented |

### Built-in Function Registry

The MF2 specification defines a [default function registry](https://unicode.org/reports/tr35/tr35-messageFormat.html#function-registry). The following table shows the implementation status:

| Function | Spec Status | Implementation |
|----------|-------------|----------------|
| `:string` | Default | Implemented (pass-through coercion) |
| `:number` | Default | Implemented via `Cldr.Number` |
| `:integer` | Default | Implemented via `Cldr.Number` with integer format |
| `:date` | Default | Implemented via `Cldr.Date` with `style`/`length` options (optional dep) |
| `:time` | Default | Implemented via `Cldr.Time` with `style`/`precision` options (optional dep) |
| `:datetime` | Default | Implemented via `Cldr.DateTime` with `dateStyle`/`timeStyle`/`dateLength`/`timePrecision` options (optional dep) |
| `:percent` | Extended | Implemented via `Cldr.Number` with percent format |
| `:currency` | Extended | Implemented via `Cldr.Number` with `currency`/`currencyDisplay`/`currencySign` options |
| `:unit` | Extended | Implemented via `Cldr.Unit` with `unit`/`unitDisplay` options (optional dep) |

### Differences from ICU4C Reference Implementation

The Elixir implementation has been validated against the ICU4C reference implementation (via NIF) using the official MF2 conformance test suite. Across 119 comparable test cases, 100% produce identical output.

#### Markup Handling

Both the Elixir implementation and ICU4C render markup nodes as empty strings. The MF2 specification does not mandate a particular string output for markup — it is left to the implementation.

#### Unbound Variable Fallback

When a variable is referenced but no binding is provided:

- **ICU4C**: produces a fallback string `{$variableName}`
- **Elixir**: produces an empty string and tracks the unbound variable in the return metadata

The Elixir implementation returns unbound variable information programmatically via the `{:error, iolist, bound, unbound}` return tuple, allowing callers to handle missing bindings as they see fit.

#### Supported Number Formatting Options

The following MF2 number formatting options are mapped to their `ex_cldr_numbers` equivalents:

| MF2 Option | CLDR Mapping | Description |
|---|---|---|
| `minimumFractionDigits` | `:fractional_digits` | Minimum number of decimal places (pads with zeros) |
| `maximumFractionDigits` | Format pattern (e.g. `#,##0.##`) | Maximum number of decimal places (truncates/rounds) |
| `useGrouping=never` | `format: "##0.#"` | Suppresses grouping separators |
| `useGrouping=min2` | `minimum_grouping_digits: 2` | Groups only when 2+ digits in the highest group |
| `useGrouping=auto` | Default locale behaviour | Uses the locale default (same as omitting the option) |
| `useGrouping=always` | Default locale behaviour | Uses the locale default |
| `numberingSystem` | `:number_system` | Selects a numbering system (e.g. `arab`, `latn`, `deva`). Must be valid for the locale. |
| `select=plural` | `Cldr.Number.PluralRule.plural_type/2` with `:Cardinal` | Default for `:number`. Matches variant keys by CLDR cardinal plural category. |
| `select=ordinal` | `Cldr.Number.PluralRule.plural_type/2` with `:Ordinal` | Matches variant keys by CLDR ordinal plural category. |
| `select=exact` | Literal equality | Matches variant keys by exact value only — no plural category resolution. |

These options can be combined. For example, `minimumFractionDigits=1 maximumFractionDigits=4 useGrouping=never` will pad to at least 1 decimal place, truncate at 4, and suppress grouping separators.

The following MF2 number formatting options are not yet implemented:

- `signDisplay`
- `notation` (`compact`, `scientific`, `engineering`)
- `minimumIntegerDigits`
- `minimumSignificantDigits` / `maximumSignificantDigits`

Standard number, integer, and percent formatting without these explicit options works correctly and produces locale-appropriate output.

#### Date/Time Formatting Options

The `:date`, `:time`, and `:datetime` functions accept ISO 8601 string literals which are automatically parsed into Elixir date/time structs. They also accept `Date`, `NaiveDateTime`, and `DateTime` structs directly via bindings.

| Function | Option | CLDR Mapping | Description |
|----------|--------|--------------|-------------|
| `:date` | `style` / `length` | `:format` | Date format style (`short`, `medium`, `long`, `full`) |
| `:time` | `style` | `:format` | Time format style (`short`, `medium`, `long`, `full`) |
| `:time` | `precision` | `:format` | `second` → `:medium`, `minute` → `:short` |
| `:datetime` | `style` | `:date_format` + `:time_format` | Sets both date and time style |
| `:datetime` | `dateStyle` / `dateLength` | `:date_format` | Date portion style |
| `:datetime` | `timeStyle` / `timePrecision` | `:time_format` | Time portion style/precision |

The following MF2 date/time formatting options are not yet implemented:

- Field options: `weekday`, `era`, `year`, `month`, `day`, `hour`, `minute`, `second`, `fractionalSecondDigits`, `timeZoneName` — these would map to CLDR skeleton atoms via the `:format` option (e.g., `{$dt :datetime year=numeric month=short day=numeric}` → `format: :yMMMd`)
- `hourCycle` (`h11`, `h12`, `h23`, `h24`) — controls 12-hour vs 24-hour clock
- `calendar` — selects a calendar system (e.g., `buddhist`, `islamic`)

Style-based formatting (`dateStyle`, `timeStyle`, `style`, `length`, `precision`) works correctly and produces locale-appropriate output.

#### Unicode NFC Normalization

The Elixir implementation applies NFC normalization to variable names, literal values, and binding keys, matching the MF2 specification requirements.

#### Unknown / Custom Functions

When a message references a function not known to the implementation:

- **ICU4C**: produces a fallback string like `{$var :unknownFn}` or `{:unknownFn}`
- **Elixir**: falls back to string coercion of the operand value

#### Literal / Number Ambiguity

Edge cases involving numeric-looking literals (e.g. `0E1`, `1E+2`) may be interpreted differently between the two implementations due to parser-level disambiguation. These are uncommon in real-world messages.

#### Plural Category Selection

The `:number` and `:integer` functions support plural category matching when used as selectors in `.match` expressions. The `select` option controls the matching behaviour:

- **`select=plural`** (default for `:number` and `:integer`): Resolves the numeric value to a CLDR cardinal plural category (`zero`, `one`, `two`, `few`, `many`, `other`) using `Cldr.Number.PluralRule.plural_type/2`. Exact numeric keys (e.g. `1`, `42`) are matched first, then plural category keys.
- **`select=ordinal`**: Resolves to CLDR ordinal plural categories (e.g. in English: 1→`one`, 2→`two`, 3→`few`, 4→`other`).
- **`select=exact`**: Matches by literal equality only — no plural category resolution.

When `:integer` is used as a selector, the value is truncated to an integer before matching (e.g. `1.2` matches key `1`).
