defmodule Cldr.Message.Sigil.Test do
  use ExUnit.Case, async: true
  import Cldr.Message.Sigil

  doctest Cldr.Message.Sigil

  test "sigil_M" do
    assert ~M"{0} {1, plural,
  one {est

    {2, select,
      female {allée}
      other {allé}}}
  other {sont

    {2, select,
      female {allées}
      other {allés}}}} à {3}" ==
             "{0} {1, plural,\n  one {est\n\n    \n    {2, select, \n      female {allée}\n      other {allé}}}\n  other {sont\n\n    \n    {2, select, \n      female {allées}\n      other {allés}}}} à {3}"
  end

  test "sigil_m" do
    assert ~m"{0} {1, plural,
      one {est {2, select, female {allée} other  {allé}}}
      other {sont {2, select, female {allées} other {allés}}}
    } à {3}" ==
             "{0} {1, plural,\n  one {est \n    {2, select, \n      female {allée}\n      other {allé}}}\n  other {sont \n    {2, select, \n      female {allées}\n      other {allés}}}} à {3}"
  end

  test "sigil_m with pretty printing" do
    assert ~m"{0} {1, plural,
      one {est {2, select, female {allée} other  {allé}}}
      other {sont {2, select, female {allées} other {allés}}}
    } à {3}"p ==
             "{0} {1, plural,\n  one {est \n    {2, select, \n      female {allée}\n      other {allé}}}\n  other {sont \n    {2, select, \n      female {allées}\n      other {allés}}}} à {3}"
  end

  test "sigil_m with interpolation" do
    var = "{0}"

    assert ~m"#{var} {1, plural,
      one {est {2, select, female {allée} other  {allé}}}
      other {sont {2, select, female {allées} other {allés}}}
    } à {3}" ==
             "{0} {1, plural,\n  one {est \n    {2, select, \n      female {allée}\n      other {allé}}}\n  other {sont \n    {2, select, \n      female {allées}\n      other {allés}}}} à {3}"
  end
end
