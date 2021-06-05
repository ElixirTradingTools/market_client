defmodule MarketClient.Resource do
  use TypedStruct

  typedstruct do
    field :broker, {atom, keyword}, enforce: true
    field :asset_id, {atom, atom, binary | {atom, atom}}, enforce: true
    field :listener, function, enforce: true
    field :options, keyword
  end
end
