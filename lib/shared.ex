defmodule MarketClient.Shared do
  alias String, as: S

  def as_list(thing) do
    case thing do
      s when is_binary(s) -> [s]
      l when is_list(l) -> l
    end
  end

  def upcase_atom(atom) when is_atom(atom) do
    to_string(atom) |> S.upcase()
  end

  def extract_bids_asks(%{
        "prices" => [
          %{
            "asks" => [%{"liquidity" => ask_liq, "price" => best_ask}],
            "bids" => [%{"liquidity" => bid_liq, "price" => best_bid}]
          }
        ]
      }) do
    %{bid: {best_ask, ask_liq}, ask: {best_bid, bid_liq}}
  end

  def oanda_handler(msg) do
    case msg do
      %{data: data} ->
        data
        |> Jason.decode!()
        |> extract_bids_asks()
        |> IO.inspect()

      msg ->
        IO.inspect(msg)
    end
  end
end
