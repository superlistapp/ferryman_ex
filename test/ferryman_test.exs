defmodule FerrymanTest do
  use ExUnit.Case
  doctest Ferryman

  test "greets the world" do
    assert Ferryman.hello() == :world
  end
end
