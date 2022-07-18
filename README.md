# Cldr Messages

![Build Status](http://sweatbox.noexpectations.com.au:8080/buildStatus/icon?job=cldr_messages)
[![Hex.pm](https://img.shields.io/hexpm/v/ex_cldr_messages.svg)](https://hex.pm/packages/ex_cldr_messages)
[![Hex.pm](https://img.shields.io/hexpm/dw/ex_cldr_messages.svg?)](https://hex.pm/packages/ex_cldr_messages)
[![Hex.pm](https://img.shields.io/hexpm/l/ex_cldr_messages.svg)](https://hex.pm/packages/ex_cldr_messages)

## Installation

```elixir
def deps do
  [
    {:ex_cldr_messages, "~> 0.14.0"}
  ]
end
```

Documentation is at [https://hexdocs.pm/ex_cldr_messages](https://hexdocs.pm/ex_cldr_messages).

## Introduction

Implements the [ICU Message Format](https://unicode-org.github.io/icu/userguide/format_parse/messages) for Elixir.

In any application that addresses audiences from different cultures, the need arises to support the presentation of user interfaces, messages, alerts and other content in the appropriate language for a user.

For [nearly 30 years](https://www.gnu.org/software/gettext/manual/gettext.html#gettext) the go-to solution for this requirement in many computer languages is [gettext](https://www.gnu.org/software/gettext). There is a full-featured [implementation for Elixir](https://hex.pm/packages/gettext) that is installed by default with [Phoenix](https://hex.pm/packages/phoenix) with over 10,000,000 downloads.

Given the maturity and widespread adoption of `Gettext`, why implement another format? Leveraging the content from the [Unicode CLDR](https://cldr.unicode.com) project we can address some of the shortcomings of `Gettext`. A good description of motivations and differences can be found in [this presentation](https://docs.google.com/presentation/d/1ZyN8-0VXmod5hbHveq-M1AeQ61Ga3BmVuahZjbmbBxo/pub?start=false&loop=false&delayms=3000&slide=id.g1bc43a82_2_14) by Mark Davis from Google in 2012.

Two specific shortcomings that the ICU message format addresses:

### Grammatical Gender

Many languages inflect in gender specific way. One example in French might be:

```elixir
# You are the only participant for a male and female
Vous êtes le seul participant
Vous êtes la seule participante

# Married for a male and a female
Marié
Mariée
```

In `Gettext` this requires individual messages and conditional code in the application in order to present the correct message to an audience.  This is compounded by the fact that some languages have more than two [grammatical genders](https://en.wikipedia.org/wiki/Grammatical_gender) (most have two and four but some are attested with up to 20).

The ICU message format provides a mechanism (the [select format](https://support.crowdin.com/icu-message-syntax/#select) that helps translator and UX designers implement a single message to easily encapsulate messages conditional on grammatical gender (or any other selector).

### Standardised plural rules

Although `Gettext` supports pluralization for messages through the [Gettext.Plural module in Elixir](https://hexdocs.pm/gettext/Gettext.Plural.html) and the `Gettext` functions like `Gettext.ngettext/4`, the plural rules for a language have to be implemented for each message. Given the wide differences in how plural forms are structured in different languages this can be a material challenge.  For example:

* English has two plural forms: singular and plural
* French applies the singular rule to two values (0 and 1) and a plural form to larger groupings
* Japanese does not differentiate
* Russian has 4 categories
* Arabic has 6 categories

Since CLDR has a strong set of pluralization rules defined for ~500 locales, each of which is supported by [ex_cldr](https://hex.pm/packages/ex_cldr), the ICU message format can reuse these pluralization rules in a simple and consistent fashion using the [plural format](https://support.crowdin.com/icu-message-syntax/#plural).

## Getting Started

In common with other [ex_cldr](https://hex.pm/packages/ex_cldr)-based libraries, a `Cldr.Message` provider module needs to be configured as part of a [CLDR backend](https://hexdocs.pm/ex_cldr/readme.html#backend-module-configuration) module definitiom. For example:
```elixir
# Note the configuration of the Cldr.Message provider module
# The provider Cldr.Number is required, all the others are optional
# but if configured provide easy formatting of dates, times, lists and units
defmodule MyApp.Cldr do
  use Cldr,
    locales: ["en", "fr", "ja", "he", "th", "ar"],
    default_locale: "en",
    providers: [Cldr.Number, Cldr.DateTime, Cldr.Unit, Cldr.List, Cldr.Calendar, Cldr.Message]
end
```

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
Further information on ICU message formats is [here](message_format.html).

## Message formatting API

Using the above messages as examples:

```elixir
iex> Cldr.Message.format! "My name is {name}", name: "Kip"
"My name is Kip"

iex> Cldr.Message.format!  "On {taken_date, date, short} {name} took {num_photos, plural,
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

## Gettext integration

As of [Gettext 0.19](https://hex.pm/packages/gettext/0.19.0), `Gettext` supports user-defined [interpolation modules](https://hexdocs.pm/gettext/Gettext.html#module-backend-configuration). This makes it easy to combine the power of ICU message formats with the broad `gettext` ecosystem and the inbuilt support for `gettext` in [Phoenix](https://hex.pm/packages/phoenix).  The documentation for [Gettext](https://hexdocs.pm/gettext/Gettext.html#content) should be followed with considerations in mind:

1. A Gettext backend module should use the `:interpolation` option defined referring to the `ex_cldr_messages` backend you have defined.
2. The message format is in the ICU message format (instead of the Gettext format).

### Defining a Gettext Interpolation Module

Any [ex_cldr](https://hex.pm/packages/ex_cldr) [backend module](https://hexdocs.pm/ex_cldr/readme.html#backend-module-configuration) that has a `Cldr.Message` provider configured can be used as an interpolation module. Here is an example:
```elixir
# CLDR backend module
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

# Define an interpolation module for ICU messages
defmodule MyApp.Gettext.Interpolation do
  use Cldr.Gettext.Interpolation, cldr_backend: MyApp.Cldr

end

# Define a gettext module with ICU message interpolation
defmodule MyApp.Gettext do
  use Gettext, otp_app: :ex_cldr_messages, interpolation: MyApp.Gettext.Interpolation
end

```
Now you can proceed to use `Gettext` in the normal manner, most typically with the `gettext/3` macro.

