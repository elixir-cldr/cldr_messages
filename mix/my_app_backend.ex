defmodule MyApp.Cldr do
  use Cldr,
    locales: ["en", "fr", "ja"],
    default_locale: "en",
    providers: [Cldr.Number, Cldr.DateTime, Cldr.Unit, Cldr.List, Cldr.Calendar],
    message_formats: %{
      USD: [format: :long]
    }
end
