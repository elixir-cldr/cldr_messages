defmodule Cldr.Message.PrintTest do
  use ExUnit.Case

  test "to_string" do
    message = """
     {gender_of_host, select,
        female {
          {num_guests, plural, offset: 1
            =0 {{host} does not give a party.}
            =1 {{host} invites {guest} to her party.}
            =2 {{host} invites {guest} and one other person to her party.}
            other {{host} invites {guest} and # other people to her party.}}}
        male {
          {num_guests, plural, offset: 1
            =0 {{host} does not give a party.}
            =1 {{host} invites {guest} to his party.}
            =2 {{host} invites {guest} and one other person to his party.}
            other {{host} invites {guest} and # other people to his party.}}}
        other {
          {num_guests, plural, offset: 1
            =0 {{host} does not give a party.}
            =1 {{host} invites {guest} to their party.}
            =2 {{host} invites {guest} and one other person to their party.}
            other {{host} invites {guest} and # other people to their party.}}}}
    """

    {:ok, parsed} =
      message
      |> String.trim()
      |> Cldr.Message.V1.Parser.parse()

    {:ok, parsed2} =
      parsed
      |> Cldr.Message.V1.Print.to_string()
      |> Cldr.Message.V1.Parser.parse()

    assert parsed2 == parsed

    {:ok, parsed3} =
      parsed
      |> Cldr.Message.V1.Print.to_string(pretty: true)
      |> Cldr.Message.V1.Parser.parse()

    assert parsed2 == parsed
    assert parsed3 == parsed
  end

  test "to_string when there is syntax literals" do
    message = "'{foo}'"

    {:ok, parsed} =
      message
      |> String.trim()
      |> Cldr.Message.V1.Parser.parse()

    {:ok, parsed2} =
      parsed
      |> Cldr.Message.V1.Print.to_string()
      |> Cldr.Message.V1.Parser.parse()

    assert parsed2 == parsed

    {:ok, parsed3} =
      parsed
      |> Cldr.Message.V1.Print.to_string(pretty: true)
      |> Cldr.Message.V1.Parser.parse()

    assert parsed2 == parsed
    assert parsed3 == parsed
  end
end
