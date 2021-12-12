require Cldr.Message

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
