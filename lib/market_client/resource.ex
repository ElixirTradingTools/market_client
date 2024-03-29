defmodule MarketClient.Resource do
  @moduledoc """
  This struct specifies what data to collect, which broker to use, and
  where to send each packet upon receipt.
  """
  use TypedStruct

  typedstruct do
    field :broker, {atom, keyword}, enforce: true
    field :asset_id, {atom, atom, binary | {binary, binary}}, enforce: true
    field :options, keyword
  end
end
