defmodule Ferryman.Server do
  @moduledoc """
  This module provides the Server API to start a JSONRPC 2.0 Server
  instance.

  ## Overview

  First, let's define a JSONRPC2 handler, and define the functions we want to be
  handled by RPC calls.

      defmodule ExampleHandler do
        use JSONRPC2.Server.Handler

        def handle_request("add", [x, y]) do
          x + y
        end
      end

  Now we can start our Ferryman Server.

      iex> {:ok, pid} = Ferryman.Server.start_link(redis_config: [], channels: ["mychannel"], handler: ExampleHandler)

  The default `redis_config` will look for a redis instance on `"localhost:6379"`.
  For more configuration options, please check the [Redix Docs](https://hexdocs.pm/redix/Redix.html#module-ssl).

  You can define a list of `channels`, and pass the `handler` module.
  """
  use GenServer

  defmodule State do
    @moduledoc false
    defstruct [:client, :handler, :channels]
  end

  @doc """
  Starts a new Ferryman.Server, which takes the following keyword list as arguments:

  ## Example

      iex> Ferryman.Server.start_link(redis_config: [], channels: ["mychannel"], handler: ExampleHandler)
      {:ok, pid}
  """
  @spec start_link(redis_config: keyword(), channels: list(String.t()), handler: module()) ::
          :ignore | {:error, any} | {:ok, pid}
  def start_link(opts) when is_list(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def put_reply(pid, id, message) do
    GenServer.call(pid, {:put_reply, id, message})
  end

  @impl true
  def init(redis_config: redis_config, channels: channels, handler: handler) do
    {:ok, pubsub} = Redix.PubSub.start_link(redis_config)
    {:ok, _ref} = Redix.PubSub.subscribe(pubsub, channels, self())
    {:ok, client} = Redix.start_link(redis_config)

    {:ok, %State{client: client, channels: channels, handler: handler}}
  end

  @impl true
  def handle_call({:put_reply, id, msg}, _from, state) do
    Redix.pipeline(state.client, [
      ["MULTI"],
      ["RPUSH", id, msg],
      ["EXPIRE", id, 24 * 3600],
      ["EXEC"]
    ])

    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:stop, _from, state) do
    {:stop, :normal, state}
  end

  @impl true
  def handle_call(_msg, _from, state) do
    {:stop, :error, state}
  end

  @impl true
  def handle_info(
        {:redix_pubsub, _pubsub, _ref, :message, %{channel: _channel, payload: message}},
        state
      ) do
    self = self()
    spawn_link(fn -> handle_request(self, message, state.handler) end)
    {:noreply, state}
  end

  @impl true
  def handle_info({:redix_pubsub, pubsub, _ref, :disconnect, _message}, state) do
    Redix.PubSub.subscribe(pubsub, state.channels)
    {:noreply, state}
  end

  @impl true
  def handle_info({:redix_pubsub, _pubsub, _ref, _type, _message}, state) do
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, _state), do: :ok

  defp handle_request(parent, message, handler) do
    case handler.handle(message) do
      :noreply ->
        :noop

      {:reply, message} ->
        {:ok, %{"id" => id}} = Jason.decode(message)
        put_reply(parent, id, message)
    end
  end
end
