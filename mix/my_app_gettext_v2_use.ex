defmodule MyApp.Gettext.V2.Use do
  use Gettext, backend: MyApp.Gettext.V2

  # Simple variable substitution
  def greeting(name),
    do: gettext("{{Hello {$name}!}}", %{"name" => name})

  # Number formatting
  def item_count(count),
    do: gettext("{{{$count :number}}}", %{"count" => count})

  # Currency formatting
  def price(amount),
    do: gettext("{{{$amount :currency currency=USD}}}", %{"amount" => amount})

  # Date formatting
  def event_date(date),
    do: gettext("{{{$date :date dateStyle=long}}}", %{"date" => date})

  # Plural selection with .input/.match
  def cart_message(count),
    do:
      gettext(
        ".input {$count :number}\n.match $count\n0 {{Your cart is empty.}}\n1 {{You have one item.}}\n* {{You have {$count :number} items.}}",
        %{"count" => count}
      )

  # Unit formatting
  def distance(value),
    do: gettext("{{{$value :unit unit=kilometer}}}", %{"value" => value})
end
