# Cldr Messages

Implements the [ICU Message Format]()

The code in this repository is not ready for use.

## Basic message format

```
On {takenDate, date, short} {name} took {numPhotos, plural,
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

