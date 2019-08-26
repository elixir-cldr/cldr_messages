# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :ex_cldr,
  default_backend: MyApp.Cldr,
  default_locale: "en"

config :ex_money,
  default_cldr_backend: MyApp.Cldr

config :ex_doc,
  pure_links: true
