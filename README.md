# MarketClient

A simple universal client for various brokers and data providers. Currently includes (to various degrees):
* Coinbase
* Binance
* Binance US
* FTX
* FTX US
* Polygon
* Oanda

The project is work-in-progress. Contributors guide will be coming soon.

Features are being added on an as-needed basis. You are encouraged to use this module in your projects
and submit merge requests for any features you'd like to add or modify. Elixir makes it very easy to use a local directory as a dependency, so clone this project and then add the following to your `mix.ex`
dependencies.
```
{:market_client, path: "/your/local/path/to/this/project"}
```

## How To Supervise

MarketClient will run as many WebSocket and/or HTTP clients as needed to supply the requested resource.
You'll need to add the `MarketClient.Registry` and `MarketClient.DynamicSupervisor` to your supervision
tree. Here's a minimal example:

```elixir
defmodule Foo.Application do
  use Application

  @impl true
  def start(_type, _args) do
    [
      {Registry, keys: :unique, name: MarketClient.Registry},
      MarketClient.DynamicSupervisor
    ]
    |> Supervisor.start_link(strategy: :one_for_one, name: Foo.Supervisor)
  end
end
```

## Example Usage
```
import MarketClient

new(:coinbase, {:crypto, :quotes, {:eth, :usd}}, &IO.inspect/1) |> start()

new(:ftx, {:crypto, :quotes, {:eth, :usd}}, &IO.inspect/1) |> start()

new(:binance, {:crypto, :quotes, {:eth, :usdt}}, &IO.inspect/1) |> start()

new(:binance_us, {:crypto, :ohlc_1minute, {:eth, :usd}}, &IO.inspect/1) |> start()

opts = [key: "X"]
new({:polygon, opts}, {:stock, :quotes, "msft"}, &IO.inspect/1) |> start()

opts = [key: "X"]
new({:polygon, opts}, {:forex, :quotes, {:gbp, :aud}}, &IO.inspect/1) |> start()

opts = [key: "X"]
new({:polygon, opts}, {:crypto, :quotes, {:btc, :usd}}, &IO.inspect/1) |> start()

opts = [key: "X", account_id: "X"]
new({:oanda, opts}, {:forex, :quotes, {:eur, :usd}}, &IO.inspect/1) |> start()

opts = [key: "X", account_id: "X"]
new({:oanda, opts}, {:forex, :ohlc_1minute, {:eur, :usd}}, &IO.inspect/1) |> start()
```
