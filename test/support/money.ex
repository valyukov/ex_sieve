defmodule Money do
  defstruct amount: 0

  def new(int) when is_integer(int), do: %Money{amount: int}
  def new(_), do: raise(ArgumentError, "expects integer")
end
