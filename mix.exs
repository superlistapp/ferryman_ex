defmodule Ferryman.MixProject do
  use Mix.Project

  def project do
    [
      app: :ferryman_ex,
      version: "0.1.0",
      elixir: "~> 1.13",
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
      {:jsonrpc2, "~> 2.0"},
      {:jason, "~> 1.0"},
      {:redix, "~> 1.1"}
    ]
  end
end
