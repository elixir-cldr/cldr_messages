# Message Format Specification

Messages are user-visible strings, often with variable elements like names,
numbers and dates. Message strings are typically translated into the different
languages of a UI, and translators move around the variable elements according
to the grammar of the target language.

For this to work in many languages, a message has to be written and translated
as a single unit, typically a string with placeholder syntax for the variable
elements. If the user-visible string were concatenated directly from fragments
and formatted elements, then translators would not be able to rearrange the
pieces, and they would have a hard time translating each of the string
fragments.

This document is an edited version of the [official ICU documentation](https://unicode-org.github.io/icu/userguide/format_parse/messages/) edited
to reflect the implementation in [ex_cldr_messages](https://hex.pm/packages/ex_cldr_messages).

## Message Format Overview

The ICU Message Format uses message `"pattern"` strings with
variable-element placeholders enclosed in {curly braces}. The
argument syntax can include formatting details, otherwise a
default format is used.

### Complex Argument Types

Certain types of arguments select among several choices which are nested
`Message Format` pattern strings. Keeping these choices together in one message
pattern string facilitates translation in context, by one single translator.
(Commercial translation systems often distribute different messages to different
translators.)

*   Use a `"plural"` argument to select sub-messages based on a numeric value,
    together with the plural rules for the specified language.
*   Use a `"select"` argument to select sub-messages via a fixed set of keywords.
*   Use of the old `"choice"` argument type is discouraged. It cannot handle
    plural rules for many languages, and is clumsy for simple selection.

It is tempting to cover only a minimal part of a message string with a complex
argument (e.g., plural). However, this is difficult for translators for two
reasons: 1. They might have trouble understanding how the sentence fragments in
the argument sub-messages interact with the rest of the sentence, and 2. They
will not know whether and how they can shrink or grow the extent of the part of
the sentence that is inside the argument to make the whole message work for
their language.

**Recommendation:** If possible, use complex arguments as the outermost
structure of a message, and write **full sentences** in their sub-messages. If
you have nested select and plural arguments, place the **select** arguments
(with their fixed sets of choices) on the **outside** and nest the plural
arguments (hopefully at most one) inside.

For example:

```text
"{gender_of_host, select, "
  "female {"
    "{num_guests, plural, offset:1 "
      "=0 {{host} does not give a party.}"
      "=1 {{host} invites {guest} to her party.}"
      "=2 {{host} invites {guest} and one other person to her party.}"
      "other {{host} invites {guest} and # other people to her party.}}}"
  "male {"
    "{num_guests, plural, offset:1 "
      "=0 {{host} does not give a party.}"
      "=1 {{host} invites {guest} to his party.}"
      "=2 {{host} invites {guest} and one other person to his party.}"
      "other {{host} invites {guest} and # other people to his party.}}}"
  "other {"
    "{num_guests, plural, offset:1 "
      "=0 {{host} does not give a party.}"
      "=1 {{host} invites {guest} to their party.}"
      "=2 {{host} invites {guest} and one other person to their party.}"
      "other {{host} invites {guest} and # other people to their party.}}}}"
```

**Note:** In a plural argument like in the example above, if the English message
has both `=0` and `=1` (up to `=offset`+1) then it does not need a "`one`"
variant because that would never be selected. It does always need an "`other`"
variant.

**Note:** *The translation system and the translator together need to add
["`one`", "`few`" etc. if and as necessary per target
language](http://cldr.unicode.org/index/cldr-spec/plural-rules).*

### Quoting/Escaping

If syntax characters occur in the text portions, then they need to be quoted by
enclosing the syntax in pairs of ASCII apostrophes. A pair of ASCII apostrophes
always represents one ASCII apostrophe, similar to `%%` in `printf` representing one `%`,
although this rule still applies inside quoted text. ("`This '{isn''t}' obvious`" → "`This {isn't} obvious`")

*   Recommendation: Use the real apostrophe (single quote) character `’` (U+2019)
    for human-readable text, and use the ASCII apostrophe `'` (U+0027) only in
    program syntax, like quoting in Message Format. See the annotations for
    U+0027 Apostrophe in The Unicode Standard.

### Argument formatting

Arguments are formatted according to their type, using the default `ex_cldr`
formatters for those types, unless otherwise specified. For unknown types the
the function `to_string/0` will be called. Formatters are supported for:

* Numbers (integer, float and Decimal) through [ex_cldr_numbers](https://hex.pm/packages/ex_cldr_numbers)
* Dates, Times and DateTimes through [ex_cldr_dates_times](https://hex.pm/packages/ex_cldr_dates_times)
* Units of measure through [ex_cldr_units](https://hex.pm/packages/ex_cldr_units)
* Money through [ex_money](https://hex.pm/packages/ex_money)

There are also several ways to control the formatting.

#### Predefined styles (recommended)

You can specify the `arg_style` to be one of the predefined values `short`, `medium`,
`long`, `full` (to get one of the standard forms for dates / times) and `integer`,
`currency`, `percent` (for number formatting).

#### Format the parameters separately (recommended)

You can format the parameter as you need **before** calling `Cldr.Message.format/3`, and
then passing the resulting string as a parameter to `Cldr.Message.format/3`.

This offers maximum control, and is preferred to using custom format objects
(see below).

#### String patterns (discouraged)

These can be used for numbers, dates, and times, but they are locale-sensitive,
and they therefore would need to be localized by your translators, which adds
complexity to the localization, and placeholder details are often not accessible
by translators. If such a pattern is not localized, then users see confusing
formatting. Consider using skeletons instead of patterns in your message
strings.

Allowing translators to localize date patterns is error-prone, as translators
might make mistakes (resulting in invalid CLDR date formatter syntax).
Also, CLDR provides curated patterns for many locales, and using your own pattern means
that you don't benefit from that CLDR data and the results will likely be
inconsistent with the rest of the patterns that CLDR uses.

It is also a bad internationalization practice, because most companies only
translate into "generic" versions of the languages (French, or Spanish, or
Arabic). So the translated patterns get used in tens of countries. On the other
hand, skeletons are localized according to the locale, which
should include regional variants (e.g., “fr-CA”).

## Message Format Syntax

`ex_cldr_messages` prepares strings for display to users, with optional arguments (variables/placeholders). The arguments can occur in any order, which is necessary for translation into languages with different grammars.

A message is constructed from a pattern string with arguments in {curly braces} which will be replaced by formatted values.

* Arguments can be named (using identifiers) or numbered (using small ASCII-digit integers).

* An argument might not specify any format type. In this case, a Number value is formatted with a default (for the locale) Number Format, a Date value is formatted with a default (for the locale) Date Format, and so on for a Unit, Money and Curency. For any other value its `to_string/0` is called.

* An argument might specify a "simple" type for which the specified Format object is created, cached and used.

* An argument might have a "complex" type with nested MessageFormat sub-patterns. During formatting, one of these sub-messages is selected according to the argument value and recursively formatted.

When formatting, `Cldr.Message.format/3` takes a collection of argument values and writes an output string. The argument values may be passed as a list (when the pattern contains only numbered arguments) or as a Map (which works for both named and numbered arguments).

Each argument is matched with one of the input values by list index or map key and formatted according to its pattern specification. A numbered pattern argument is matched with a map key that contains that number as an ASCII-decimal-digit string (without leading zero).

### Patterns and Their Interpretation

Message Format uses patterns of the following form:
```
 message = messageText (argument messageText)*
 argument = noneArg | simpleArg | complexArg
 complexArg = choiceArg | pluralArg | selectArg | selectordinalArg

 noneArg = '{' argNameOrNumber '}'
 simpleArg = '{' argNameOrNumber ',' argType [',' argStyle] '}'
 choiceArg = '{' argNameOrNumber ',' "choice" ',' choiceStyle '}'
 pluralArg = '{' argNameOrNumber ',' "plural" ',' pluralStyle '}'
 selectArg = '{' argNameOrNumber ',' "select" ',' selectStyle '}'
 selectordinalArg = '{' argNameOrNumber ',' "selectordinal" ',' pluralStyle '}'

 choiceStyle: see ChoiceFormat
 pluralStyle: see PluralFormat
 selectStyle: see SelectFormat

 argNameOrNumber = argName | argNumber
 argName = [^[[:Pattern_Syntax:][:Pattern_White_Space:]]]+
 argNumber = '0' | ('1'..'9' ('0'..'9')*)

 argType = "number" | "date" | "time" | "spellout" | "ordinal" | "duration"
 argStyle = "short" | "medium" | "long" | "full" | "integer" | "currency" | "percent" | argStyleText
```

Messages can contain quoted literal strings including syntax characters. A quoted literal string begins with an ASCII apostrophe and a syntax character (usually a {curly brace}) and continues until the next single apostrophe. A double ASCII apostrophe inside or outside of a quoted string represents one literal apostrophe.
Quotable syntax characters are the `{curly braces}` in all message parts, plus the `#` sign in a message immediately inside a `pluralStyle`, and the '|' symbol in a messageText immediately inside a `choiceStyle`.

In argStyleText, every single ASCII apostrophe begins and ends quoted literal text, and unquoted {curly braces} must occur in matched pairs.

Recommendation: Use the real apostrophe (single quote) character \\u2019 for human-readable text, and use the ASCII apostrophe (\\u0027 ' ) only in program syntax, like quoting in MessageFormat. See the annotations for U+0027 Apostrophe in The Unicode Standard.

The choice argument type is deprecated. Use plural arguments for proper plural selection, and select arguments for simple selection among a fixed set of choices.

### Examples

See the examples in the [README](/README.md)
