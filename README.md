# ⚡️ FerrymanEx

[![CI](https://github.com/superlistapp/ferryman_ex/actions/workflows/main.yml/badge.svg)](https://github.com/superlistapp/ferryman_ex/actions/workflows/main.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/ferryman_ex.svg)](https://hex.pm/packages/ferryman_ex)
[![docs](https://img.shields.io/badge/docs-hexpm-blue.svg)](https://hexdocs.pm/ferryman_ex/)

`FerrymanEx` is a pure Elixir JSONRPC2 Client & Server realization.

[Ferryman](https://github.com/superlistapp/ferryman) is a JSONRPC 2.0 Client & Server realization for Erlang and Ruby.

## 💻 Installation

```elixir
def deps do
  [
    {:ferryman_ex, github: "superlistapp/ferryman_ex"}
  ]
end
```

## 🚀 Getting Started

To get started, make sure you have a running instance of Redis.

`FerrymanEx` uses [Redix](https://hex.pm/packages/redix) as redis driver.

You can start a local redis instance by running `docker run --name my-redis -p 6379:6379 -d redis`

### Server

First, let's define a JSONRPC2 handler, and define the functions we want to be
handled by RPC calls.

```elixir
defmodule ExampleHandler do
  use JSONRPC2.Server.Handler

  def handle_request("add", [x, y]) do
    x + y
  end
end
```

Now we can start our Ferryman Server.

```elixir
iex> {:ok, pid} = Ferryman.Server.start_link(redis_config: [], channels: ["mychannel"], handler: ExampleHandler)
```

The default `redis_config` will look for a redis instance on `"localhost:6379"`.
For more configuration options, please check the [Redix Docs](https://hexdocs.pm/redix/Redix.html#module-ssl).

You can define a list of `channels`, and pass the `handler` module.

### Client

To start communicating with the Ferryman server, let's first start our redis process:

```elixir
iex> {:ok, redis} = Redix.start_link()
```

Now we can simply call the functions, the server has implemented:

```elixir
iex> Ferryman.Client.call(redis, "mychannel", "add", [1, 2])
{:ok, 3}
```

## 🤓 Used Libraries

[Redix](https://hex.pm/packages/redix)
[Jason](https://hex.pm/packages/jason)
[JSONRPC2](https://hex.pm/packages/jsonrpc2)

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

Copyright (c) 2022 Superlist
