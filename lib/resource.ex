defmodule MarketClient.Resource do
  use TypedStruct

  typedstruct do
    field :broker, Tuple.t(), enforce: true
    field :asset_id, Tuple.t(), enforce: true
    field :listener, Function.t(), enforce: true
    field :options, Map.t() | nil
  end
end
