# Changelog

## Cldr_Messages v0.13.0

This is the changelog for Cldr_Messages v0.13.0 released on January 2nd, 2022.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_messages/tags)

### Bug Fixes

* Don't add `:gettext` to `Mix.compilers/0` because it gets inherited into client applications and we want `Gettext` to remain optional. Thanks to @trarbr for the report.

* Fix typos. Thanks as always to @kianmeng

## Enhancements

* Add an Elixir formatter plugin for `sigil_M`. For example:
```elixir
[
  inputs: ["mix.exs", "{config,lib,test,mix}/**/*.{ex,exs}"],
  locals_without_parens: [docp: 1, defparsec: 2, defparsec: 3],
  plugins: [Cldr.Formatter.Plugin]
]
```

## Cldr_Messages v0.12.0

This is the changelog for Cldr_Messages v0.12.0 released on January 1st, 2022.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_messages/tags)

### Enhancements

The primary focus of this release is gettext integration. The effort is kindly driven by @maennchen and the majority of the work is his.

* Add `Cldr.Message.format_to_iolist/3` which formats a binary message into an iolist. This helps with incrementally binding placeholders where some may be bound at compile time and others at runtime. It also makes integration with `gettext` simpler since this function returns a list of completed bindings and a list of bindings that were not found.

* Adds an implementation of `Gettext.Interpolation` to support `gettext` integration.

## Cldr_Messages v0.11.0

This is the changelog for Cldr_Messages v0.11.0 released on May 23rd, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_messages/tags)

### Enhancements

* Add `Cldr.Message.bindings/1` to extract the names of variable bindings for a message

* Add option `:allow_positional_args` to `Cldr.Message.format/3`. The default is `true`.

* Add argument `allow_positional_args?` to `Cldr.Message.Parser.parse/2`

## Cldr_Messages v0.10.0

This is the changelog for Cldr_Messages v0.10.0 released on April 8th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_messages/tags)

### Enhancements

* Use `Cldr.default_backend!/0` if available

## Cldr_Messages v0.9.0

This is the changelog for Cldr_Messages v0.9.0 released on November 18th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_messages/tags)

### Enhancements

* Supports number arguments to be either a number or a tuple of the form `{number, keyword_list_of_formatting_options}`. This provides an escape hatch for developers to influence formatting of the number beyond the textual format of the message.  For example:

```elixir
# Uses the currency for the current locale
iex> Cldr.Message.format "this is {one, number, currency}", one: 1
{:ok, "this is $1.00"}

# Forces the :MXP currency
iex> Cldr.Message.format "this is {one, number, currency}", one: {1, currency: :MXP}
{:ok, "this is MXP 1.00"}
```

## Cldr_Messages v0.8.0

This is the changelog for Cldr_Messages v0.8.0 released on September 27th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_messages/tags)

### Enhancements

* Fix `Cldr.Message.Print.to_string/2` to omit blank spaces at the end of lines when pretty printing.

## Cldr_Messages v0.7.0

This is the changelog for Cldr_Messages v0.7.0 released on September 26th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_messages/tags)

### Enhancements

* Allow `nimble_parsec` versions `~> 0.5 or ~> 1.0`

## Cldr_Messages v0.6.0

This is the changelog for Cldr_Messages v0.6.0 released on September 26th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_messages/tags)

### Enhancements

* Add `Cldr.Message.canonical_message/2` that converts a string message into a canonical form. This allows for fuzzy matching between two messages that may have different formatting (this is possible since the CLDR message format allows for non-formatting whitespace in parts of the syntax).

* Add documentation for some of the key functions. Much more documentation required before 1.0 release.

## Cldr_Messages v0.5.0

This is the changelog for Cldr_Messages v0.5.0 released on September 22nd, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_messages/tags)

### Enhancements

* Adds compile time checking that bindings are provided to the `format/3` macro wherever possible

* Supports later versions of `ex_cldr` and friends, `ex_money` as well as Elixir 1.11 without warnings

## Cldr_Messages v0.4.0

This is the changelog for Cldr_Messages v0.4.0 released on August 29th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_messages/tags)

### Bug Fixes

* Conditionally compile functions that depend on optional dependencies

## Cldr_Messages v0.3.0

This is the changelog for Cldr_Messages v0.3.0 released on August 29th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_messages/tags)

### Breaking Changes

* Standardize on the `Cldr.Message.format/3` as the public api. `Cldr.Message.to_string/3` is removed.

### Enhancements

* Add the macro `<backend>.Cldr.Message.format/3` to parse messages at compile time as a way to optiise performance at runtime. To use it add `import <backend>.Cldr.Message` to your module and use `format/3`.  An example:

```elixir
defmodule SomeModule do
  import MyApp.Cldr.Message

  def my_function do
    format("this is a string with a param {param}", param: 3)
  end
end
```

* Add `Cldr.Message.format_to_list/3` formats to an `io_list`

### Bug Fixes

* Fix dialyzer warnings.  There are some warnings from combinators that will require `nimble_parsec` version 0.5.2 to be published before they are resolved.

## Cldr_Messages v0.2.0

This is the changelog for Cldr_Messages v0.2.0 released on August 27th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_messages/tags)

### Enhancements

* Uses `Cldr.Number.to_string/3` to format simple arguments that are numeric (integer, float and decimal).  This gives a localised number format. An example:

```elixir
iex> Cldr.Message.to_string "You have {number} jelly beans", number: 1234
"You have 1,234 jelly beans"
```

* Similarly applies localized formatting for dates, times, datetimes.

## Cldr_Messages v0.1.0

This is the changelog for Cldr_Messages v0.1.0 released on August 26th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_messages/tags)

* Initial release.  This release implements `Cldr.Message.to_string/3` and `Cldr.Message.format/3`

This initial release is the basis for building a complete message localization solution as an alternative to [Gettext](https://hex.pm/packages/gettext).  There is a long way to go until that is accomplished.

