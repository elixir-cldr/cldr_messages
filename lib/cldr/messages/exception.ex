defmodule Cldr.Message.ParseError do
  @moduledoc """
  Exception raised when parsing an ICU message format

  """
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end

defmodule Cldr.Message.PositionalArgsNotPermitted do
  @moduledoc """
  Exception raised when parsing an ICU message format
  and positional arguments are not permitted

  """
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end

