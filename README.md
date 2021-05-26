# MarketClient

A simple universal client for various brokers and data providers. Currently includes (to various degrees):
* Polygon
* Oanda
* Binance
* Coinbase

The project is work-in-progress. Features are being added on an as-needed basis. You are encouraged to
use this module in your projects and submit merge requests for any features you'd like to add or modify.
Elixir makes it very easy to use a local directory as a dependency, so clone this project and then add
the following to your `mix.ex` dependencies.
```
{:market_client, path: "/your/local/path/to/this/project"}
```

## Example Usage
```
res = MarketClient.new({:coinbase, nil}, {:crypto, {:eth, :usd}}, &IO.inspect/1)
{:ok, pid} = MarketClient.start_link(res)
MarketClient.start(pid, res)
MarketClient.stop(pid, res)

res = MarketClient.new({:binance, nil}, {:crypto, {:eth, :usdt}}, &IO.inspect/1)
{:ok, pid} = MarketClient.start_link(res)
MarketClient.start(pid, res)
MarketClient.stop(pid, res)

res = MarketClient.new({:polygon, %{key: "XXXX"}}, {:stock, {"MSFT", nil}}, &IO.inspect/1)
{:ok, pid} = MarketClient.start_link(res)
MarketClient.start(pid, res)
MarketClient.stop(pid, res)

res = MarketClient.new({:polygon, %{key: "XXXX"}}, {:forex, {:gbp, :aud}}, &IO.inspect/1)
{:ok, pid} = MarketClient.start_link(res)
MarketClient.start(pid, res)
MarketClient.stop(pid, res)

# OANDA
alias MarketClient.{DataProvider, Resource}

MarketClient.new({:oanda, %{
        practice: true,
        account_id: "XXXX",
        key: "XXXX"
    }},
    {:forex, {:aud, :nzd}},
    %{
        data_type: :candlesticks,
        resolution: {1, :minute}
    },
    &IO.inspect/1
)
|> Vendor.Oanda.start_link()
```

## Example HTTP With FTX_US

```
# https://ftx.us/api/markets/ETH/USD/candles?resolution=60&start_time=1621200276&end_time=1621201476
# https://ftx.us/api/markets/eth/usd/candles?resolution=60&limit=50&start_time=0&end_time=1621200227

res = MarketClient.new(:ftx_us, {:crypto, {:eth, :usd}}, fn {:ok, %{body: body}} ->
    body |> Jason.decode!() |> Map.get("result") |> IO.inspect()
end)

MarketClient.new(:ftx_us, {:crypto, {:eth, :usd}}, &IO.inspect/1) |> MarketClient.start_ws()

Supervisor.start_link([{MarketClient, [res]}], strategy: :one_for_one, name: MySupervisor)

MarketClient.http_fetch(res)
```
