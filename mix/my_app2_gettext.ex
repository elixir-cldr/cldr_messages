defmodule MyApp.Gettext.Interpolation2 do
  use Cldr.Gettext.Interpolation, cldr_backend: MyApp2.Cldr
end

defmodule MyApp2.Gettext do
  use Gettext.Backend, otp_app: :ex_cldr_messages, interpolation: MyApp.Gettext.Interpolation2
end
