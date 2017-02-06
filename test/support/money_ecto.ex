defmodule Money.Ecto.Type do
  @behaviour Ecto.Type

  def type, do: :integer

  def cast(%Money{}=money), do: {:ok, money}
  def cast(_), do: :error

  def load(int) when is_integer(int), do: {:ok, Money.new(int)}

  def dump(%Money{amount: amount}), do: {:ok, amount}
  def dump(_), do: :error
end
