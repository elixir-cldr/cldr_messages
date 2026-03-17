defmodule MyApp.Gettext.Interpolation.V2 do
  use Cldr.Gettext.Interpolation.V2, cldr_backend: MyApp.Cldr
end

defmodule MyApp.Gettext.V2 do
  use Gettext.Backend,
    otp_app: :ex_cldr_messages,
    interpolation: MyApp.Gettext.Interpolation.V2,
    priv: "priv/my_app_gettext_v2"
end
