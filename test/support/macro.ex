defmodule MessageMacro do
  import MyApp.Cldr.Message

  def test do
    format("this is my message with a {number}", number: 1)
  end
end
