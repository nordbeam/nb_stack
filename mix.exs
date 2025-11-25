defmodule NbStack.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/nordbeam/nb_stack"

  def project do
    [
      app: :nb_stack,
      version: @version,
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description(),
      docs: docs(),
      name: "NbStack",
      source_url: @source_url,
      homepage_url: @source_url
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      # Installer framework
      {:igniter, "~> 0.7", only: [:dev, :test]},

      # Documentation
      {:ex_doc, "~> 0.30", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    Meta-package and installer for the complete nb_ frontend stack. Orchestrates installation of nb_vite, nb_inertia, nb_routes, nb_ts, and nb_serializer for a modern Phoenix frontend development experience with Vite, Inertia.js, type-safe routing, and TypeScript integration.
    """
  end

  defp package do
    [
      name: "nb_stack",
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url
      },
      files: ~w(
        lib
        mix.exs
        README.md
        LICENSE
        CHANGELOG.md
        .formatter.exs
      )
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end
end
