defmodule MarketClient.MixProject do
  use Mix.Project

  def project do
    [
      app: :market_client,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.0"},
      {:typed_struct, "~> 0.2.1"},
      {:websockex, "~> 0.4.2"},
      {:mint, "~> 1.0"},
      {:castore, "~> 0.1.0"}
    ]
  end
end
