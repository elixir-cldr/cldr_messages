# Changelog for Cldr_Messages v0.2.0

This is the changelog for Cldr_Messages v0.2.0 released on August 27th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_messages/tags)

### Enhancements

* Uses `Cldr.Number.to_string/3` to format simple arguments that are numeric (integer, float and decimal).  This gives a localised number format. An example:

```elixir
iex> Cldr.Message.to_string "You have {number} jelly beans", number: 1234
"You have 1,234 jelly beans"
```

* Similarly applies localized formatting for dates, times, datetimes and lists.

# Changelog for Cldr_Messages v0.1.0

This is the changelog for Cldr_Messages v0.1.0 released on August 26th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_messages/tags)

* Initial release.  This release implements `Cldr.Message.to_string/3` and `Cldr.Message.format/3`

This initial release is the basis for building a complete message localization solution as an alternative to [Gettext](https://hex.pm/packages/gettext).  There is a long way to go until that is accomplished.

