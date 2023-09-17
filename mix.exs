defmodule PhilColumns.Mixfile do
  use Mix.Project

  def project do
    [
      app: :glific_phil_columns,
      version: "3.1.0",
      # build_path: "../../_build",
      # config_path: "../../config/config.exs",
      # deps_path: "../../deps",
      # lockfile: "../../mix.lock",
      elixir: "~> 1.0",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  defp description do
    """
    A fork from a a full featured Elixir/Ecto seeding and factory solution (phil_columns) providing means for dev and prod seeding as well as factories for test.
    """
  end

  defp package do
    [
      name: :glific_phil_columns,
      files: [
        "lib",
        "mix.exs",
        "README*",
        "LICENSE*"
      ],
      maintainers: ["C. Jason Harrelson"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/glific/phil_columns-ex",
        "Docs" => "https://hexdocs.pm/phil_columns/3.0.0"
      }
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      mod: {PhilColumns, []},
      applications: [
        :logger
      ]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:ecto_sql, "~> 3.0"},
      {:ex_doc, "~> 0.20", only: :dev},
      {:inflex, "~> 2.0"}
    ]
  end
end
