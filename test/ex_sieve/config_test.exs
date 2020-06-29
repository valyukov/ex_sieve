defmodule ExSieve.ConfigTest do
  use ExUnit.Case

  alias ExSieve.{Post, Address}
  alias ExSieve.Config

  test "invalid options are discarded" do
    refute Config.new([], %{foo: 1}, Address) |> Map.has_key?(:foo)
  end

  test "repo options override defaults" do
    assert %Config{max_depth: 4} = Config.new([max_depth: 4], %{}, Post)
  end

  test "schema options override defaults" do
    assert %Config{max_depth: 3} = Config.new([max_depth: 4], %{}, Address)
  end

  test "call options override all" do
    assert %Config{max_depth: 1} = Config.new([], %{max_depth: 1}, Address)
  end
end
