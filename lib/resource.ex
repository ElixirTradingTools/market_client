defmodule MarketClient.Resource do
  use TypedStruct

  typedstruct do
    field :broker, Tuple.t(), enforce: true
    field :handler, Tuple.t(), enforce: true
    field :asset_id, Tuple.t(), enforce: true
    field :data_type, Atom.t(), enforce: true
    field :opts, Map.t()
  end
end
