defmodule MyApp.Gettext.Interpolation do
  use Cldr.Gettext.Interpolation, cldr_backend: MyApp.Cldr
end

defmodule MyApp.Gettext do
  use Gettext.Backend,
    otp_app: :ex_cldr_messages,
    interpolation: MyApp.Gettext.Interpolation,
    priv: "priv/my_app_gettext"
end
