defmodule MarketClient.Shared do
  @spec is_vendor_module(module) :: boolean
  @spec as_list(any) :: list
  @spec a2s_upcased(atom) :: binary
  @spec a2s_downcased(atom) :: binary
  @spec remove_whitespace(binary) :: binary
  @spec unix_now(:ms | :sec, none() | binary) :: integer

  def is_vendor_module(module) do
    [Module.split(MarketClient.Vendor), Module.split(module)]
    |> Enum.reduce(&List.starts_with?/2)
  end

  def as_list(thing) do
    case thing do
      s when is_binary(s) -> [s]
      l when is_list(l) -> l
      u -> [u]
    end
  end

  def a2s_upcased(atom) when is_atom(atom) do
    to_string(atom) |> String.upcase()
  end

  def a2s_downcased(atom) when is_atom(atom) do
    to_string(atom) |> String.downcase()
  end

  def remove_whitespace(string) do
    string |> String.replace(~r(\s|\n), "")
  end

  def unix_now(unit, timezone \\ "Etc/UTC") do
    case unit do
      :ms -> DateTime.now!(timezone) |> DateTime.to_unix(:millisecond)
      :sec -> DateTime.now!(timezone) |> DateTime.to_unix(:second)
    end
  end
end
