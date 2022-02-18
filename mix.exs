defmodule GeoStreamData.MixProject do
  use Mix.Project

  def project do
    [
      app: :geo_stream_data,
      version: "0.2.0",
      elixir: "~> 1.7",
      description: description(),
      package: package(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:seg_seg, "~> 0.1.0"},
      {:stream_data, "~> 0.5"},
      {:geo, "~> 3.0"},
      {:envelope, "~> 1.4", only: :test},
      {:jason, "~> 1.2", only: [:dev, :test]},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      validate: [
        "clean",
        "compile --warnings-as-error",
        "format --check-formatted",
        "credo",
        "dialyzer"
      ]
    ]
  end

  defp description do
    """
    Library for generating geospatial data for property testing.
    """
  end

  defp package do
    [
      files: ["lib/geo_stream_data.ex", "lib/geo_stream_data", "mix.exs", "README*"],
      maintainers: ["Powell Kinney"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/pkinney/geo_stream_data"}
    ]
  end
end
