defmodule MarketClient.Resource do
  use TypedStruct

  typedstruct do
    field :vendor, tuple, enforce: true
    field :asset_id, tuple, enforce: true
    field :listener, function, enforce: true
    field :options, map | nil
  end
end
