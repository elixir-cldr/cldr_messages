defmodule Cldr.Message.Sigil do
  @moduledoc """
  Implements sigil `~M` to canonicalize an
  ICU message.

  ICU messages allow for whitespace to be used to
  format the message for developer and translator readability.
  At the same time, `gettext` uses the message string
  as a key when resolving translations.

  Therefore a developer or translator that modifies
  the message for readability may unintentionally
  create a new message rather than replace the old one
  simply because the message strings don't match exactly.

  It is possible to use the `fuzzy` option to the task
  `mix gettext.extract` however this may not be the desired
  behaviour either.

  The sigil `~M` therefore introduces a way for the developer
  to ensure the message is in a canonical format during
  compilation and therefore both error check the message format
  and ensure the message is in a canonical form irrespective
  of developer formatting.

  """

  @doc ~S"""
  Handles the sigil `~M` for ICU message strings.

  It returns a a canonically formatted string without
  interpolations and without escape characters, except
  for the escaping of the closing sigil character
  itself.

  A canonically formatted string is pretty-printed by
  default returning a potentially multi-line
  string.  This is intended to produce a result which is
  easier to comprehend for translators.

  The modifier `u` can be applied to return
  a non-pretty-printed string.

  ## Modifi

  ## Examples

      iex> ~m(An ICU message)
      "An ICU message"

  However, if you want to re-use the sigil character itself on
  the string, you need to escape it.

  """
  defmacro sigil_M({:<<>>, _meta, [message]}, modifiers) when is_binary(message) do
    options = Cldr.Message.Sigil.options(modifiers)
    canonical_message = Cldr.Message.canonical_message!(message, options)

    quote do
      unquote(canonical_message)
    end
  end

  # sigil_m is marked private since it implies constructing messages
  # at compile time which would be an unusual use case and quite
  # possibly an anti-pattern. Real world usage will dictate if
  # its useful.

  # @doc ~S"""
  # Handles the sigil `~m` for ICU message strings.
  #
  # It returns a canonically formatted string as if it
  # was a double quoted string, unescaping characters
  # and replacing interpolations.
  #
  # ## Examples
  #
  #     iex> ~m(An ICU message)
  #     "An ICU message"
  #
  #     iex> ~m(An ICU messag#{:e})
  #     "An ICU message"
  #
  # """

  @doc false
  defmacro sigil_m({:<<>>, _meta, [message]}, modifiers) when is_binary(message) do
    options = Cldr.Message.Sigil.options(modifiers)
    message = Macro.unescape_string(message)
    canonical_message = Cldr.Message.canonical_message!(message, options)

    quote do
      unquote(canonical_message)
    end
  end

  defmacro sigil_m({:<<>>, meta, pieces}, modifiers) do
    options = Cldr.Message.Sigil.options(modifiers)
    message = {:<<>>, meta, unescape_tokens(pieces)}

    quote do
      Cldr.Message.canonical_message!(unquote(message), unquote(options))
    end
  end

  @doc false
  def options([pretty]) when pretty in [?u, ?U] do
    [pretty: false]
  end

  def options(_modifiers) do
    [pretty: true]
  end

  @doc false
  defp unescape_tokens(tokens) do
    Enum.map(tokens, fn
      token when is_binary(token) -> Macro.unescape_string(token)
      other -> other
    end)
  end
end
