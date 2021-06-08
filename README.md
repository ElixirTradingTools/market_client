# MarketClient

A simple universal client for various brokers and data providers. Currently includes (to various degrees):
* CoinbasePro
* Binance
* Binance US
* FTX
* FTX US
* Polygon
* Oanda

The project is work-in-progress. Contributors guide is forthcoming.

Features are being added on an as-needed basis. You are encouraged to use this module in your projects
and submit merge requests for any features you'd like to add or modify. Elixir makes it very easy to use a local directory as a dependency, so clone this project and then add the following to your `mix.exs`
dependencies.
```
{:market_client, path: "/your/local/path/to/this/project"}
```

## How To Supervise

MarketClient will run as many WebSocket and/or HTTP clients as needed to satisfy the requested resource.
You'll need to add the `MarketClient.Registry` and `MarketClient.DynamicSupervisor` to your supervision
tree. A minimal example would be:

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
```elixir
# Not that you should import MarketClient, but for brevity's sake in this example...
import MarketClient

new(:coinbase_pro, {:crypto, :quotes, {:eth, :usd}})
|> Stream.each(&IO.puts/1)
|> Stream.run()

new(:ftx, {:crypto, :quotes, {:eth, :usd}})
|> Stream.each(&IO.puts/1)
|> Stream.run()

new(:binance, {:crypto, :quotes, {:eth, :usdt}})
|> Stream.each(&IO.puts/1)
|> Stream.run()

new(:binance_us, {:crypto, :ohlc_1minute, {:eth, :usd}})
|> Stream.each(&IO.puts/1)
|> Stream.run()

new({:polygon, [key: "X"]}, {:stock, :quotes, "msft"})
|> Stream.each(&IO.puts/1)
|> Stream.run()

new({:polygon, [key: "X"]}, {:forex, :quotes, {:gbp, :aud}})
|> Stream.each(&IO.puts/1)
|> Stream.run()

new({:polygon, [key: "X"]}, {:crypto, :quotes, {:btc, :usd}})
|> Stream.each(&IO.puts/1)
|> Stream.run()

{:oanda, [key: "X", account_id: "X"]}
|> new({:forex, {:quotes, start: "", end: ""}, {:eur, :usd}})
|> Stream.each(&IO.puts/1)
|> Stream.run()

{:oanda, [key: "X", account_id: "X"]}
|> new({:forex, :ohlc_1minute, {:eur, :usd}})
|> Stream.each(&IO.puts/1)
|> Stream.run()
```
