# Cldr Messages

![Build Status](http://sweatbox.noexpectations.com.au:8080/buildStatus/icon?job=cldr_messages)
[![Hex.pm](https://img.shields.io/hexpm/v/ex_cldr_messages.svg)](https://hex.pm/packages/ex_cldr_messages)
[![Hex.pm](https://img.shields.io/hexpm/dw/ex_cldr_messages.svg?)](https://hex.pm/packages/ex_cldr_messages)
[![Hex.pm](https://img.shields.io/hexpm/l/ex_cldr_messages.svg)](https://hex.pm/packages/ex_cldr_messages)

## Introduction and Getting Started

Implements the [ICU Message Format](http://userguide.icu-project.org/formatparse/messages) for Elixir.

In any application that addresses audiences from different cultures, the need arises to support the presentation of user interfaces, messages, alerts and other content in the appropriate language for a user.

For [nearly 30 years](https://www.gnu.org/software/gettext/manual/gettext.html#gettext) the go-to solution for this requirement in many computer langauges is [gettext](https://www.gnu.org/software/gettext). There is a full-featured [implementation for Elixir](https://hex.pm/packages/gettext) that is installed by default with [Phoenix](https://hex.pm/packages/phoenix) with over 10,000,000 downloads.

Given the maturity and widespread adoption of `Gettext`, why implement another format? Leveraging the content from the [Unicode CLDR](https://cldr.unicode.com) project we can address some of the shortcomings of `Gettext`. A good description of motivations and differences can be found in [this presentation](https://docs.google.com/presentation/d/1ZyN8-0VXmod5hbHveq-M1AeQ61Ga3BmVuahZjbmbBxo/pub?start=false&loop=false&delayms=3000&slide=id.g1bc43a82_2_14) by Mark Davis from Google in 2012.

Two specific shortcomings that the ICU message format addresses:

### Grammatical Gender

Many languages inflect in gender specific way. One example in French might be:
```
 # You are the only participant for a male and female
 Vous êtes the seul participant
 Vous êtes la seule participante

 # Married for a male and a female
 Marié
 Mariée
```
In `Gettext` this requires individual messages and conditional code in the application in order to present the correct message to an audience.  This is compounded by the fact that some languages have more than two g[rammatical genders](https://en.wikipedia.org/wiki/Grammatical_gender) (most have been two and four but but some are attested with up to 20.

The ICU message format provides a mechanism (the [choice format](#Choice_format)) that helps translator and UX designers implement a single message to easily encapsulate messages conditional on grammatical gender (or any other selector)

### Standardised plural rules

Although `Gettext` supports pluralisation for messages through the [Gettext.Plural module in Elixir](https://hexdocs.pm/gettext/Gettext.Plural.html) and the `Gettext` functions like `Gettext.ngettext/4`, the plural rules for a language have to be implemented for each message. Give the wide differences in how plural forms are structured in different languages this can be a material challenge.  For example:

* English has two plural forms: singular and plural
* French applies the singular rule to two values and a plural form to larger groupings
* Japanese does not differentiate
* Russian has 4 categories
* Arabic has 6 categories

Since CLDR has a strong set of pluralization rules defined for ~500 locales, each of which is supported by [ex_cldr for Elixir](https://hex.pm/ex_cldr), the ICU message format can reuse these pluralization rules in a simple and consisten fashion using the [plural format]{#Plural_Format}

## Message format overview

ICU message formats are Elixir strings with embedded formatting directives inserted between `{}`. Some examples:

```elixir
 # Insert the binding `name` into the string
 "My name is {name}"

 # Insert a date, formatting in a localized `short` format plus a localized plural form
 # for the binding `num_photos`
 "On {taken_date, date, short} {name} took {num_photos, plural,
   =0 {no photos.}
   =1 {one photo.}
   other {# photos.}}"

 # Insert localized messages based upon the gender of the audience with
 # appropriate localized plural forms
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

## Message formatting

Using the above messages as examples:

```elixir
iex> Cldr.Message.format! "My name is {name}", name: "Kip"
"My name is Kip"

iex> Cldr.Message.to_string!  "On {taken_date, date, short} {name} took {num_photos, plural,
       =0 {no photos.}
       =1 {one photo.}
       other {# photos.}}", taken_date: Date.utc_today, name: "Kip", num_photos: 10
"On 8/26/19 Kip took 10 photos."
```

As of `ex_cldr_messages` version 0.3.0 a macro form is introduced which parses the message at compile time in order to optimize performance at run time. To use the macro, a backend module must be imported (or required) into a module that uses formatting.  For example:

```elixir
defmodule SomeModule do
  # Import a <backend>.Cldr.Message module
  import MyApp.Cldr.Message

  def my_function do
    format("this is a string with a param {param}", param: 3)
  end
end
```

## Installation

```elixir
def deps do
  [
    {:ex_cldr_messages, "~> 0.3.0"}
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

* [X] Support decimal numbers for selectors
* [X] Won't do. Support `spellout` format for `Money.t` types ? (Maybe can't because of floating point RBNF rule limitations)
* [X] Check for all occurences in README's for `Cldr.get_current_locale/0` and change it to `Cldr.get_locale/0`
* [X] Implement explicit `=0` argument selection for plurals
* [X] Add remaining formatters for dates, times, datetimes
* [X] In `ex_money`, if no configured `default_cldr_backend`, delegate to `Cldr.default_backend/0`
* [X] Implement a `{arg, list, format}` formatter that uses `ex_cldr_lists`
* [X] Implement a `{arg, unit, format}` formatter that uses `ex_cldr_units`
* [X] Implement `offset`
* [X] Implement custom formats in backend config provider; probably requires updating the `struct` in `ex_cldr`
* [X] Implement `selectordinal`
* [X] Assert that `plural`, `select` and `selectordinal` all have an `other` clause
* [X] Tests
* [X] @specs
* [ ] Dialyzer. Ask José to push nimble_parsec 0.5.2 to remove combinator errors
* [ ] Documentation
* [ ] Implement `to_message` for parse trees.  This will define a canonical form which we can use to compare messages and create keys.