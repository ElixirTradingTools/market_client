defmodule MarketClient.Resource do
  @moduledoc """
  This struct specifies what data to collect, which broker to use, and
  where to send each packet upon receipt.
  """
  use TypedStruct

  @type pair :: {binary, binary}
  @type ticker :: binary

  typedstruct do
    field :broker, {atom, keyword}, enforce: true
    field :watch, keyword(pair) | keyword(ticker), enforce: true
    field :options, keyword
  end
end
