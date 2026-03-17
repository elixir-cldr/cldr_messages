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
.match {$count :integer}
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
Cldr.Message.format!("{{Hello, {$name}!}}", %{"name" => "Alice"})
Cldr.Message.format!("{{Hello, {$name}!}}", name: "Alice")
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

Formats a number as a currency amount. Requires the `ex_money` package.

```
{$amount :currency currency=USD}
```

### `:date`

Formats a date value. Requires the `ex_cldr_dates_times` package.

```
{$when :date}
{$when :date style=short}
{$when :date style=full}
```

**Styles**: `short`, `medium` (default), `long`, `full`.

### `:time`

Formats a time value. Requires the `ex_cldr_dates_times` package.

```
{$when :time}
{$when :time style=short}
```

**Styles**: `short`, `medium` (default), `long`, `full`.

### `:datetime`

Formats a datetime value. Requires the `ex_cldr_dates_times` package.

```
{$when :datetime}
{$when :datetime style=long}
```

**Styles**: `short`, `medium` (default), `long`, `full`.

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
- Plain text
- Expressions (`{$var}`, `{$var :func}`, `{|literal|}`)
- Markup elements (`{#tag}`, `{/tag}`, `{#tag /}`)
- Escape sequences (`\\`, `\{`, `\}`, `\|`)

## Pattern Matching with `.match`

The `.match` statement selects one of several variant patterns based on the runtime value of one or more selector expressions.

### Single Selector

```
.input {$count :number}
.match {$count :integer}
0 {{No items.}}
1 {{One item.}}
* {{You have {$count} items.}}
```

### Multiple Selectors

```
.input {$gender :string}
.input {$count :integer}
.match {$gender :string} {$count :integer}
male 1 {{He has one item.}}
female 1 {{She has one item.}}
* 1 {{They have one item.}}
male * {{He has {$count} items.}}
female * {{She has {$count} items.}}
* * {{They have {$count} items.}}
```

### Variant Keys

Each variant has one key per selector. Keys can be:

- **Literal keys**: match when the selector value equals the literal (e.g., `0`, `1`, `|male|`, `female`)
- **Catchall `*`**: matches any value (lowest priority)

### Matching Rules

1. All keys in a variant must match their corresponding selector values
2. Literal keys are matched by string or numeric equality
3. Variants are sorted by specificity: fewer `*` keys = more specific
4. The most specific matching variant is selected
5. If no variant matches, the result is an error

## Markup

MF2 supports markup elements for structured output. The Elixir implementation renders these as HTML-like tags.

### Open and Close Tags

```
{{Click {#link}here{/link} to continue.}}
```

Renders as: `Click <link>here</link> to continue.`

### Self-Closing Tags

```
{{An image: {#img src=|photo.jpg| /}}}
```

Renders as: `An image: <img />`

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

### Simple Greeting

```elixir
Cldr.Message.format!("{{Hello, {$name}!}}", %{"name" => "World"})
# => "Hello, World!"
```

### Number Formatting

```elixir
Cldr.Message.format!("""
.input {$count :number}
{{You have {$count} items in your cart.}}
""", %{"count" => 1234})
# => "You have 1,234 items in your cart."
```

### Plural Selection

```elixir
Cldr.Message.format!("""
.input {$count :number}
.match {$count :integer}
0 {{Your cart is empty.}}
1 {{You have one item in your cart.}}
* {{You have {$count} items in your cart.}}
""", %{"count" => 3})
# => "You have 3 items in your cart."
```

### Local Variable Binding

```elixir
Cldr.Message.format!("""
.input {$first :string}
.input {$last :string}
.local $greeting = {|Welcome|}
{{Dear {$first} {$last}, {$greeting}!}}
""", %{"first" => "Jane", "last" => "Doe"})
# => "Dear Jane Doe, Welcome!"
```

### Gender and Plural Selection

```elixir
Cldr.Message.format!("""
.input {$gender :string}
.input {$count :number}
.match {$gender :string} {$count :integer}
male 1 {{He bought one item.}}
female 1 {{She bought one item.}}
* 1 {{They bought one item.}}
male * {{He bought {$count} items.}}
female * {{She bought {$count} items.}}
* * {{They bought {$count} items.}}
""", %{"gender" => "female", "count" => 3})
# => "She bought 3 items."
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
| Markup (open, close, self-closing) | Parsed and rendered as HTML-like tags |
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
| `:date` | Default | Implemented via `Cldr.Date` (optional dep) |
| `:time` | Default | Implemented via `Cldr.Time` (optional dep) |
| `:datetime` | Default | Implemented via `Cldr.DateTime` (optional dep) |
| `:percent` | Extended | Implemented via `Cldr.Number` with percent format |
| `:currency` | Extended | Implemented via `Cldr.Number` with currency format |

### Differences from ICU4C Reference Implementation

The Elixir implementation has been validated against the ICU4C reference implementation (via NIF) using the official MF2 conformance test suite. Across 119 comparable test cases, 63% produce identical output. The known differences are documented below.

#### Markup Handling

The Elixir interpreter renders MF2 markup nodes as HTML-like tags (e.g. `<bold>text</bold>`). The ICU4C reference implementation silently drops all markup from the output. Neither behaviour is mandated by the MF2 specification, which leaves markup handling to the implementation. The Elixir approach preserves markup structure in the output, which is useful for downstream rendering.

#### Unbound Variable Fallback

When a variable is referenced but no binding is provided:

- **ICU4C**: produces a fallback string `{$variableName}`
- **Elixir**: produces an empty string and tracks the unbound variable in the return metadata

The Elixir implementation returns unbound variable information programmatically via the `{:error, iolist, bound, unbound}` return tuple, allowing callers to handle missing bindings as they see fit.

#### Number Formatting Options

Some MF2 number formatting options are not yet mapped to their `ex_cldr_numbers` equivalents:

- `minimumFractionDigits` / `maximumFractionDigits`
- `useGrouping`
- `signDisplay`
- `notation` (`compact`, `scientific`, `engineering`)

Standard number, integer, and percent formatting without these explicit options works correctly and produces locale-appropriate output.

#### Unicode NFC Normalization

The MF2 specification calls for NFC normalization of output text. The Elixir implementation does not currently apply NFC normalization. This can produce different output when messages contain pre-composed vs decomposed Unicode characters (e.g. U+1E0C vs D + U+0323). In practice this affects very few messages.

#### Unknown / Custom Functions

When a message references a function not known to the implementation:

- **ICU4C**: produces a fallback string like `{$var :unknownFn}` or `{:unknownFn}`
- **Elixir**: falls back to string coercion of the operand value

#### Literal / Number Ambiguity

Edge cases involving numeric-looking literals (e.g. `0E1`, `1E+2`) may be interpreted differently between the two implementations due to parser-level disambiguation. These are uncommon in real-world messages.

#### Plural Category Selection

The MF2 specification allows `:integer` and `:number` to function as selectors that resolve to CLDR plural categories (`zero`, `one`, `two`, `few`, `many`, `other`). The current Elixir implementation matches selector values by literal equality rather than plural category. This means variants keyed by plural category names (e.g. `one`, `other`) are matched as string/number literals, not as CLDR plural rules. Exact-value keys (e.g. `0`, `1`, `42`) work correctly.
