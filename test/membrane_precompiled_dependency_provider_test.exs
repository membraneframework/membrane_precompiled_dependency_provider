defmodule MembranePrecompiledDependencyProviderTest do
  use ExUnit.Case
  doctest MembranePrecompiledDependencyProvider

  test "greets the world" do
    assert MembranePrecompiledDependencyProvider.hello() == :world
  end
end
