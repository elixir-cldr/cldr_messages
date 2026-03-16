# Exclude MF2 NIF tests when the NIF is not available
excludes =
  if Cldr.Message.V2.Nif.available?() do
    []
  else
    [:mf2_nif]
  end

ExUnit.start(exclude: excludes)
