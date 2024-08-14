defmodule Helix.MixProject do
  use Mix.Project

  @env Mix.env()

  def project do
    [
      app: :helix,
      version: "0.0.1",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.cobertura": :test,
        # Must be run in `:test` to include all possible schemas
        "db.schema.list": :test
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Helix.Application, []},
      extra_applications: extra_applications(@env) ++ [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp extra_applications(:dev), do: [:observer, :wx, :eex]
  defp extra_applications(:test), do: [:observer]
  defp extra_applications(_), do: []

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:cowboy, "~> 2.12"},
      {:rustler, "~> 0.32.0"},
      {:feebdb, path: "~/feebdb"},
      {:jose, "~> 1.11"},
      {:norm, "~> 0.13"},
      {:mox, "~> 1.1", only: :test},
      {:excoveralls, "~> 0.18.1", only: :test},
      {:req, "~> 0.4.8", only: :test}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    []
  end
end
