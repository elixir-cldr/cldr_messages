defmodule Cldr.Message.V2.Nif do
  @moduledoc """
  NIF wrapper for ICU4C MessageFormat 2.0.

  Provides `validate/1` and `format/3` functions that delegate to
  ICU's MessageFormatter implementation. The NIF is optional — when
  unavailable, `available?/0` returns `false` and calls raise
  `:nif_library_not_loaded`.
  """

  @on_load :init

  @doc false
  def init do
    path = :code.priv_dir(:ex_cldr_messages) ++ ~c"/mf2"

    case :erlang.load_nif(path, 0) do
      :ok -> :ok
      {:error, _reason} -> :ok
    end
  end

  @doc """
  Returns `true` if the MF2 NIF is loaded and available.
  """
  @spec available?() :: boolean()
  def available? do
    match?({:ok, _}, nif_validate(""))
  rescue
    _ -> false
  end

  @doc """
  Validates a MessageFormat 2 message string using ICU's parser.

  Returns `{:ok, normalized_pattern}` or `{:error, reason}`.
  """
  @spec validate(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def validate(message) when is_binary(message) do
    nif_validate(message)
  end

  @doc """
  Formats a MessageFormat 2 message string using ICU.

  Arguments are passed as a map of `%{name => value}` and
  encoded to JSON for the NIF.

  Returns `{:ok, formatted_string}` or `{:error, reason}`.
  """
  @spec format(String.t(), String.t(), map()) :: {:ok, String.t()} | {:error, String.t()}
  def format(message, locale \\ "en", args \\ %{}) when is_binary(message) do
    nif_format(message, locale, Jason.encode!(args))
  end

  # Stub NIF functions — replaced at load time
  @dialyzer {:no_return, nif_validate: 1}
  defp nif_validate(_message) do
    :erlang.nif_error(:nif_library_not_loaded)
  end

  @dialyzer {:no_return, nif_format: 3}
  defp nif_format(_message, _locale, _args_json) do
    :erlang.nif_error(:nif_library_not_loaded)
  end
end
