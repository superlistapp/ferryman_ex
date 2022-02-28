defmodule Ferryman.Client do
  def cast(redis, channel, method, params) do
    req = JSONRPC2.Request.request({method, params})

    with {:ok, json_req} <- Jason.encode(req) do
      Redix.command(redis, ["PUBLISH", channel, json_req])
    end
  end

  def call(redis, channel, method, params, timeout \\ 1) do
    multicall(redis, channel, method, params, timeout)
  end

  def multicall(redis, channel, method, params, timeout \\ 1) do
    id = random_key()
    req = JSONRPC2.Request.request({method, params, id})

    with {:ok, json_req} <- Jason.encode(req),
         {:ok, server_count} when server_count > 0 <-
           Redix.command(redis, ["PUBLISH", channel, json_req]) do
      get_value(redis, id, timeout)
    else
      {:ok, 0} -> {:error, :no_subscriber}
      error -> error
    end
  end

  def get_value(redis, id, timeout) do
    with {:ok, [_key, value]} <- Redix.command(redis, ["BLPOP", id, timeout]),
         {:ok, %{"result" => result}} <- Jason.decode(value) do
      {:ok, result}
    end
  end

  defp random_key() do
    Base.encode64(:crypto.strong_rand_bytes(10))
  end
end
