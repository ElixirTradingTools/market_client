defmodule MarketClient.Resource do
  @moduledoc false
  @doc """
  This struct specifies what data to collect, which broker to use, and
  where to send each packet upon receipt.
  """
  use TypedStruct

  typedstruct do
    field :broker, {atom, keyword}, enforce: true
    field :asset_id, {atom, atom, binary | {atom, atom}}, enforce: true
    field :listener, function, enforce: true
    field :options, keyword
  end
end
