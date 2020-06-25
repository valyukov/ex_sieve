defmodule ExSieve.Utils do
  @moduledoc false

  alias ExSieve.Config

  @spec get_error(list(any), Config.t()) :: list(any) | {:error, atom}
  def get_error(items, %Config{ignore_errors: true}), do: Enum.reject(items, &match?({:error, _}, &1))
  def get_error(items, %Config{ignore_errors: false}), do: Enum.find(items, items, &match?({:error, _}, &1))
end
