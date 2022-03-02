defmodule Ferryman.MixProject do
  use Mix.Project

  def project do
    [
      app: :ferryman_ex,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: "A pure Elixir JSONRPC2 Client & Server realization with Redix",
      name: "FerrymanEx",
      source_url: "https://github.com/superlistapp/ferryman_ex",
      docs: [
        extras: ["README.md"],
        api_reference: false,
        main: "readme"
      ]
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
      {:redix, "~> 1.1"},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Daniel Khaapamyaki"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/superlistapp/ferryman_ex"}
    ]
  end
end
