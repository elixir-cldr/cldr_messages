defmodule CldrMessagesTest do
  use ExUnit.Case
  doctest CldrMessages

  test "greets the world" do
    assert CldrMessages.hello() == :world
  end
end
