defmodule ExSieve.Config do
  @moduledoc """
  A `ExSieve.Config` can be created with a `ignore_errors` true or false
  ```
  %ExSieve.Config{
    ignore_errors: true
  }
  ```
  """
  defstruct ignore_errors: true

  @type t :: %__MODULE__{}

  @doc false
  @spec new(Keyword.t(), map) :: ExSieve.Config.t()
  def new(defaults, options \\ %{}) do
    %ExSieve.Config{ignore_errors: ignore_errors?(defaults, options)}
  end

  defp normalize_options(options) do
    Enum.reduce(options, %{}, fn {k, v}, map ->
      Map.put(map, to_string(k), v)
    end)
  end

  defp ignore_errors?(defaults, options) do
    options
    |> normalize_options
    |> Map.get("ignore_errors", Keyword.get(defaults, :ignore_errors, true))
  end
end
