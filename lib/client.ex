defmodule Ferryman.Client do
  @moduledoc """
  This module provides the Client API to communicate with a Ferryman Server.

  ## Overview

  To start communicating with the Ferryman server, let's first start our redis process:

      iex> {:ok, redis} = Redix.start_link()

  Now we can simply call the functions, the server has implemented:

      iex> Ferryman.Client.call(redis, "mychannel", "add", [1, 2])
      {:ok, 3}
  """
  @doc """
  Executes a function on the server async, without a response.

  It will be unknown, wether the Ferryman server successfully handled
  the message.
  """
  def cast(redis, channel, method, params) do
    req = JSONRPC2.Request.request({method, params})

    with {:ok, json_req} <- Jason.encode(req) do
      Redix.command(redis, ["PUBLISH", channel, json_req])
    end
  end

  @doc """
  Executes a function on the server and returns the response.

  ## Example

      iex> Ferryman.Client.call(redis, "mychannel", "add", [1, 2])
      {:ok, 3}
  """
  def call(redis, channel, method, params, timeout \\ 1) do
    case multicall(redis, channel, method, params, timeout) do
      [value | _] -> value
      _ -> {:error, :no_subscriber}
    end
  end

  @doc """
  Executes a function on the servers and returns a list of responses.

  ## Example

      iex> Ferryman.Client.multicall(redis, "mychannel", "add", [1, 2])
      {:ok, 3}
  """
  def multicall(redis, channel, method, params, timeout \\ 1) do
    id = random_key()
    req = JSONRPC2.Request.request({method, params, id})

    with {:ok, json_req} <- Jason.encode(req),
         {:ok, server_count} <- Redix.command(redis, ["PUBLISH", channel, json_req]) do
      for n <- :lists.seq(1, server_count), do: get_value(redis, id, timeout)
    end
  end

  defp get_value(redis, id, timeout) do
    with {:ok, [_key, value]} <- Redix.command(redis, ["BLPOP", id, timeout]),
         {:ok, %{"result" => result}} <- Jason.decode(value) do
      {:ok, result}
    end
  end

  defp random_key() do
    Base.encode64(:crypto.strong_rand_bytes(10))
  end
end
