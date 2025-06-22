defmodule Helix.MixProject do
  use Mix.Project

  def project do
    [
      app: :helix,
      version: "0.0.1",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      # We implement custom protocols. If consolidated, a warning will raise when recompiling such
      # implementations. To avoid this, let's just consolidate them under the `:prod` env.
      consolidate_protocols: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.cobertura": :test
      ],
      dialyzer: [plt_add_apps: [:mix]]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Helix.Application, []},
      extra_applications: extra_applications(Mix.env()) ++ [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp extra_applications(:dev), do: [:observer, :wx]
  defp extra_applications(_), do: []

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:cowboy, "~> 2.13"},
      {:rustler, "~> 0.36.0"},
      {:decimal, "~> 2.3.0"},
      {:feebdb, github: "renatomassaro/feebdb", branch: "main"},
      {:jose, "~> 1.11"},
      {:norm, "~> 0.13"},
      {:renatils, "~> 0.1.3"},
      {:docp, "~> 1.0"},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:mox, "~> 1.2", only: :test},
      {:excoveralls, "~> 0.18.5", only: :test},
      {:req, "~> 0.5.10", only: :test},
      {:mix_test_watch, "~> 1.3", only: [:dev, :test], runtime: false}
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
