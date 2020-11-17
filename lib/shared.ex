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
end
