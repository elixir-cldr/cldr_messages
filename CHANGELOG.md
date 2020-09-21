# Changelog for Cldr_Messages v0.5.0

This is the changelog for Cldr_Messages v0.5.0 released on September 22nd, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_messages/tags)

### Enhancements

* Adds compile time checking that bindings are provided to the `format/3` macro wherever possible

* Supports later versions of `ex_cldr` and friends, `ex_money` as well as Elixir 1.11 without warnings

# Changelog for Cldr_Messages v0.4.0

This is the changelog for Cldr_Messages v0.4.0 released on August 29th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_messages/tags)

### Bug Fixes

* Conditionally compile functions that depend on optional dependencies

# Changelog for Cldr_Messages v0.3.0

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

* Add `Cldr.Mesasge.format_to_list/3` formats to an `io_list`

### Bug Fixes

* Fix dialyzer warnings.  There are some warnings from combinators that will require `nimble_parsec` version 0.5.2 to be published before they are resolved.

# Changelog for Cldr_Messages v0.2.0

This is the changelog for Cldr_Messages v0.2.0 released on August 27th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_messages/tags)

### Enhancements

* Uses `Cldr.Number.to_string/3` to format simple arguments that are numeric (integer, float and decimal).  This gives a localised number format. An example:

```elixir
iex> Cldr.Message.to_string "You have {number} jelly beans", number: 1234
"You have 1,234 jelly beans"
```

* Similarly applies localized formatting for dates, times, datetimes.

# Changelog for Cldr_Messages v0.1.0

This is the changelog for Cldr_Messages v0.1.0 released on August 26th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_messages/tags)

* Initial release.  This release implements `Cldr.Message.to_string/3` and `Cldr.Message.format/3`

This initial release is the basis for building a complete message localization solution as an alternative to [Gettext](https://hex.pm/packages/gettext).  There is a long way to go until that is accomplished.

