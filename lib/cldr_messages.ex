defmodule Cldr.Message do
  @moduledoc """
  Documentation for CldrMessages.
  """
	alias Cldr.Message.Parser
	
	def to_string(message, args, options \\ []) do
		case format(message, args, options) do
			{:error, reason} -> {:error, reason}
			{:ok, message} -> {:ok, :erlang.iolist_to_binary(message)}
		end
	end
	
	def to_string!(message, args, options \\ []) do
		case to_string(message, args, options) do
			{:ok, message} -> message
			{:error, {exception, reason}} -> raise exception, reason
		end
	end
	
	def format(message, args, options \\ [])
	
  def format(message, args, options) when is_binary(message) do
		options = Keyword.merge(default_options(), options)
		
    case Parser.parse(message) do
      {:ok, result} ->
        {:ok, format(result, args, options)}

      {:ok, _result, rest} ->
        {:error,
         {Cldr.Message.ParseError, "Couldn't parse message. Error detected at #{inspect(rest)}"}}

      other ->
        other
    end
  end
		
  def format([head], args, options) do
    [format(head, args, options)]
  end
	
  def format([head | rest], args, options) do
    [format(head, args, options) | format(rest, args, options)]
  end

	def format({:literal, literal}, _args, _options) when is_binary(literal) do
		literal
	end
	
  def format({:pos_arg, arg}, args, _options) when is_map(args) do
		Map.fetch!(args, arg)
  end
	
  def format({:pos_arg, arg}, args, _options) when is_list(args) do
		Enum.at(args, arg)
  end
	
  def format({:pos_arg, arg}, args, _options) when is_tuple(args) do
		elem(args, arg)
  end

  def format({:named_arg, arg}, args, _options) when is_map(args) do
		Map.fetch!(args, arg)
  end
	
  def format({:named_arg, arg}, args, _options) when is_list(args) do
		Keyword.fetch!(args, arg)
  end
	
	def format(:value, _args, options) do
		Keyword.get(options, :arg, "")
	end
	
  def format({:simple_format, arg, type}, args, options) do
		arg = format(arg, args, options)
		format({arg, type}, args, options)
  end

  def format({:simple_format, arg, type, style}, args, options) do
		arg = format(arg, args, options)
		format({arg, type, style}, args, options)
  end
	
	def format({number, :number}, _args, options) do
		Cldr.Number.to_string!(number, options)
	end
	
	@integer_format "#"
	def format({number, :number, :integer}, _args, options) do
		options = Keyword.put(options, :format, @integer_format)
		Cldr.Number.to_string!(number, options)
	end
	
	def format({number, :number, :short}, _args, options) do
		options = Keyword.put(options, :format, :short)
		Cldr.Number.to_string!(number, options)
	end
	
	def format({number, :number, :currency}, _args, options) do
		options = Keyword.put(options, :format, :currency)
		Cldr.Number.to_string!(number, options)
	end
	
	def format({number, :number, :percent}, _args, options) do
		options = Keyword.put(options, :format, :percent)
		Cldr.Number.to_string!(number, options)
	end
	
	def format({number, :number, :permille}, _args, options) do
		options = Keyword.put(options, :format, :permille)
		Cldr.Number.to_string!(number, options)
	end
	
	def format({number, :number, format}, _args, options) when is_binary(format) do
		options = Keyword.put(options, :format, format)
		Cldr.Number.to_string!(number, options)
	end

  def format({:select, arg, selections}, args, options) do
		arg = format(arg, args, options)	
		message = Map.get(selections, arg) || other(selections)
		format(message, args, options)
  end
	
  def format({:plural, arg, plurals}, args, options) do
		format_plural(arg, Cardinal, plurals, args, options)
  end
	
  def format({:select_ordinal, arg, plurals}, args, options) do
		format_plural(arg, Ordinal, plurals, args, options)
  end
	
	defp format_plural(arg, type, plurals, args, options) do
		arg = format(arg, args, options)
		formatted_arg = Cldr.Number.to_string!(arg, options)
		
		options = 
			options
			|> Keyword.put(:type, type)
			|> Keyword.put(:arg, formatted_arg)
			
		plural_type = Cldr.Number.PluralRule.plural_type(arg, options)
		message = Map.get(plurals, plural_type) || other(plurals)
		format(message, args, options)
	end

	defp default_options do
		[locale: Cldr.get_locale(), backend: Cldr.default_backend()]
	end
	
	defp other(map) do
		Map.get(map, "other", Map.fetch!(map, :other))
	end
end
