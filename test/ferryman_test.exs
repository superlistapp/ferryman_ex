defmodule FerrymanTest do
  use ExUnit.Case

  defmodule ExampleHandler do
    use JSONRPC2.Server.Handler

    def handle_request("add", [x, y]) do
      x + y
    end
  end

  setup_all do
    {:ok, redis} = Redix.start_link(sync_connect: true)
    Redix.command!(redis, ["FLUSHALL"])
    :ok = Redix.stop(redis)
    :ok
  end

  test "successfully returns the function result" do
    assert {:ok, pid} =
             Ferryman.Server.start_link(
               redis_config: [],
               channels: ["mychannel"],
               handler: ExampleHandler
             )

    assert {:ok, redis} = Redix.start_link()
    assert {:ok, 3} = Ferryman.Client.call(redis, "mychannel", "add", [1, 2])
  end

  test "returns method not found error when function is not defined" do
    assert {:ok, pid} =
             Ferryman.Server.start_link(
               redis_config: [],
               channels: ["mychannel"],
               handler: ExampleHandler
             )

    assert {:ok, redis} = Redix.start_link()

    assert {:ok, %{"error" => %{"message" => "Method not found"}}} =
             Ferryman.Client.call(redis, "mychannel", "sub", [1, 2])
  end

  test "returns internal error on arithmetic error" do
    assert {:ok, pid} =
             Ferryman.Server.start_link(
               redis_config: [],
               channels: ["mychannel"],
               handler: ExampleHandler
             )

    assert {:ok, redis} = Redix.start_link()

    assert {:ok, %{"error" => %{"message" => "Internal error"}}} =
             Ferryman.Client.call(redis, "mychannel", "add", ["1", "2"])
  end

  test "returns no subscriber error if no server is running" do
    assert {:ok, redis} = Redix.start_link()
    assert {:error, :no_subscriber} = Ferryman.Client.call(redis, "mychannel", "add", [1, 2])
  end

  test "successfully returns multiple function results" do
    assert {:ok, pid} =
             Ferryman.Server.start_link(
               redis_config: [],
               channels: ["mychannel"],
               handler: ExampleHandler
             )

    assert {:ok, pid} =
             Ferryman.Server.start_link(
               redis_config: [port: 6379],
               channels: ["mychannel"],
               handler: ExampleHandler
             )

    assert {:ok, redis} = Redix.start_link()
    assert [{:ok, 3}, {:ok, 3}] = Ferryman.Client.multicall(redis, "mychannel", "add", [1, 2])
  end
end
