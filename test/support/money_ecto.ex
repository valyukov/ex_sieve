defmodule Money.Ecto.Type do
  use Ecto.Type

  def type, do: :integer

  def cast(%Money{} = money), do: {:ok, money}

  def cast(money) do
    case Ecto.Type.cast(:integer, money) do
      {:ok, int} -> {:ok, Money.new(int)}
      _ -> :error
    end
  end

  def load(int) when is_integer(int), do: {:ok, Money.new(int)}

  def dump(%Money{amount: amount}), do: {:ok, amount}
  def dump(_), do: :error

  def embed_as(_format), do: :self

  def equal?(money_a, money_b), do: money_a == money_b
end
