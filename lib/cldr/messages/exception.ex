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

defmodule Cldr.Message.BindError do
  @moduledoc """
  Exception raised when interpreting a
  message and a binding is missing

  """
  defexception [:message]

  def exception(message) when is_binary(message) do
    %__MODULE__{message: message}
  end

  def exception({_bound, unbound}) do
    message = "No binding was found for #{inspect unbound}"
    %__MODULE__{message: message}
  end
end