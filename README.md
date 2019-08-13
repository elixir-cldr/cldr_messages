# Cldr Messages

Implements the [ICU Message Format]()

The code in this repository is not ready for use.

## Basic message format

```elixir
On {:taken_date, date, short} {:name} took {num_photos, plural,
    =0 {no photos.}
    =1 {one photo.}
    other {# photos.}
}
```

## Installation

```elixir
def deps do
  [
    {:ex_cldr_messages, "~> 0.1.0"}
  ]
end
```

Documentation is at [https://hexdocs.pm/cldr_messages](https://hexdocs.pm/cldr_messages).

## To Do

For the initial release. This is a simple function interface to message formatting. Before 1.0 it needs to also have a means like gettext of managing messages in multiple different locales for the same message content.

* [X] Ignore whitespace between nested complex arguments at the top level. Example:
  {:select, {:named_arg, "gender_of_host"},
    %{
      "female" => [
        {:literal, "\n    "},  <---- Ignore this when its whitespace only
        {:plural, {:named_arg, "num_guests"},

* [X] Support decimal for selectors
* [X] Won't do. Support `spellout` format for `Money.t` types ? (Maybe can't because of floating point RBNF rule limitations)
* [X] Check for all occurences in README's for `Cldr.get_current_locale/0` and change it to `Cldr.get_locale/0`
* [X] Implement `=0` argument selection for plurals
* [X] Add remaining formatters for dates, times, datetimes
* [X] In `ex_money`, if no configured `default_cldr_backend`, delegate to `Cldr.default_backend`
* [X] Implement a `{arg, list, format}` formatter that uses `ex_cldr_lists`
* [X] Implement a `{arg, unit, format}` formatter that uses `ex_cldr_units`
* [ ] Implement `offset`
* [ ] Implement custom formats in backend config provider; probably requires updating the `struct` in `ex_cldr`
* [X] Implement `selectordinal`
* [ ] Implement `to_message` for parse trees.  This will define a canonical form which we can use to compare message and create keys.
* [ ] Tests
* [ ] @specs
* [ ] Dialyzer
* [ ] Documentation