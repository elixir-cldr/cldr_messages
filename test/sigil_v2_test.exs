defmodule Cldr.Message.Sigil.V2.Test do
  use ExUnit.Case, async: true
  import Cldr.Message.Sigil

  test "sigil_m with simple V2 message" do
    assert ~m"{{Hello {$name}!}}" == "{{Hello {$name}!}}"
  end

  test "sigil_m with V2 expression" do
    assert ~m"{{{$count :number}}}" == "{{{$count :number}}}"
  end

  test "sigil_m with V2 function options" do
    assert ~m"{{{$amount :currency currency=USD}}}" ==
             "{{{$amount :currency currency=USD}}}"
  end

  test "sigil_m with .input declaration" do
    assert ~m".input {$count :number}
    {{You have {$count} items.}}" ==
             ".input {$count :number}\n{{You have {$count} items.}}"
  end

  test "sigil_m with .input and .match" do
    assert ~m".input {$count :number}
    .match $count
      1 {{one item}}
      * {{{$count} items}}" ==
             ".input {$count :number}\n.match $count\n1 {{one item}}\n* {{{$count} items}}"
  end

  test "sigil_m with multiple .input declarations" do
    assert ~m".input {$gender :string}
    .input {$count :number}
    .match $gender $count
      female 1 {{she has one}}
      * * {{they have many}}" ==
             ".input {$gender :string}\n.input {$count :number}\n.match $gender $count\nfemale 1 {{she has one}}\n* * {{they have many}}"
  end

  test "sigil_m with interpolation" do
    name = "name"

    assert ~m"{{Hello {$#{name}}!}}" == "{{Hello {$name}!}}"
  end

  test "sigil_M preserves whitespace in V2 message" do
    assert ~M"{{Hello   {$name}!}}" == "{{Hello   {$name}!}}"
  end

  test "sigil_m with V2 markup" do
    assert ~m"{{Click {#button}here{/button}.}}" ==
             "{{Click {#button}here{/button}.}}"
  end

  test "sigil_m with V2 literal option values" do
    assert ~m"{{{$d :date dateStyle=long}}}" ==
             "{{{$d :date dateStyle=long}}}"
  end

  test "sigil_m with V2 .local declaration" do
    assert ~m".local $formatted = {$count :number}
    {{{$formatted} items}}" ==
             ".local $formatted = {$count :number}\n{{{$formatted} items}}"
  end
end
