defmodule Ferryman.Server do
  use GenServer

  defmodule State do
    defstruct [:client, :handler, :channels]
  end

  def start_link(opts) when is_list(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def put_reply(id, message) do
    GenServer.call(__MODULE__, {:put_reply, id, message})
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
    spawn_link(fn -> handle_request(message, state.handler) end)
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

  def handle_request(message, handler) do
    case handler.handle(message) do
      :noreply ->
        :noop

      {:reply, message} ->
        {:ok, %{"id" => id}} = Jason.decode(message)
        put_reply(id, message)
    end
  end
end
