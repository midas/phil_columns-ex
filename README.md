![PhilColumns: No Fixtures Required](https://raw.githubusercontent.com/midas/phil_columns/master/readme/PhilColumns.png)

# PhilColumns

A full featured Elixir/Ecto seeding solution providing means for dev and prod seeding.


## Installation

Add phil_columns to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:phil_columns, "~> 0.1.0"}]
end
```

Ensure phil_columns is started before your application:

```elixir
def application do
  [applications: [:phil_columns]]
end
```

Create a `Seed` module for you application:

```elixir
# lib/my_app/seed.ex

defmodule MyApp.Seed do
  defmacro __using__(_opts) do
    quote do
      use PhilColumns.Seed

      # shared code here ...
    end
  end
end
```

## Configuration

If you need to ensure applications are started before seeding, configure them like this:

```elixir
config :phil_columns,
  ensure_all_started: ~w(timex)a
```


## Usage

### Seeding Quick Start

Use the generator to create a seed.

    $ mix phil_columns.gen.seed add_things

The generator puts a seed file in place.  Add your seeding logic to the `up/1` and/or `down/1`
functions using any valid Elixir/Ecto code.

```elixir
# priv/repo/seeds/20160624153032_add_things.exs

defmodule MyApp.Repo.Seeds.AddThings do
  use MyApp.Seed

  def up(_repo) do
    # seeding logic ...
  end
end
```

Execute the seed(s).

    $ mix phil_columns.seed

### The Seed Command

The simplest usage of the seed command defaults the environment to `dev` and the version to `all`.

    $ mix phil_columns.seed

The env can be overridden by providing a switch.  The env is used to select only seeds that have been
specified for the specified env.

    $ mix phil_columns.seed --env=prod
    $ mix phil_columns.seed -e prod

### Tags and Environments

Tags and environments can be applied to seeds and filtered in command usage.  The seed generator adds the `dev`
environment by default and no tags.  This feature enables efficiency and adaptability in development seeding and
the possibility to use _PhilColumns_ seeding in production (see Production Seeding section below).

Specifying environment(s) for a seed is accomplished with the envs function.

```elixir
defmodule MyApp.Repo.Seeds.AddThings do
  use MyApp.Seed

  envs [:dev, :prod]
  # ...
end
```

To change the environment use the env switch.  When not specified the env defaults to `dev`.

    $ mix phil_columns.seed -e prod

Similary, applying tag(s) is accomplished using the tags function.

```elixir
defmodule MyApp.Repo.Seeds.AddThings do
  use MyApp.Seed

  envs [:dev, :prod]
  tags [:some_tag]
  # ...
end
```

To change the tag(s) provide them after the command command line.

    $ mix phil_columns.seed --tags=users,settings,etc
    $ mix phil_columns.seed -t users,settings,etc


## Production Seeding

### Why?

Systems often have system level data that must be seeded when bootstraping a system or as new features are rolled out.  Some
examples are settings, configurations, roles, licenses, etc.

_PhilColumns_ provides the ability to apply these system data seedings and commit them with features, analgous to an Ecto
migration. Committing seed data with features or bug fixes communicates the intention of the data more clearly than any
other strategy can.

### How?

Create a module specifically for dealing with seeding in production.

```elixir
defmodule MyApp.Deployment.Seeder do
  import Mix.Ecto
  import Mix.PhilColumns

  def seed(opts, seeder \\ &PhilColumns.Seeder.run/4) do
    repos = parse_repo(opts)
            |> List.wrap

    # set env with current_env/0 overwriting provided arg
    opts = Keyword.put( opts, :env, current_env )

    opts =
      if opts[:to] || opts[:step] || opts[:all],
        do: opts,
        else: Keyword.put(opts, :all, true)

    opts =
      if opts[:log],
        do: opts,
        else: Keyword.put(opts, :log, :info)

    opts =
      if opts[:quiet],
        do: Keyword.put(opts, :log, false),
        else: opts

    Enum.each(repos, fn repo ->
      exec_task(repo, opts, fn ->
        seeder.(repo, seeds_path(repo), :up, opts)
      end)
    end)
  end

  defp current_env do
    # implement this
    # warning: do not use Mix.env if you are doing an erlang release
  end
end
```

Use the module in the production app's remote console.

```elixir
MyApp.Deployment.Seeder.seed(tags: ~w(things stuff)a)
```
### Seeding in production when using mix release
When using `mix release`, mix itself will not be available in your release. The module below provides an example of a module that does not use mix. 
```elixir
defmodule MyApp.Deployment.Seeder do
  import Ecto.Migrator, only: [migrations_path: 2, with_repo: 2]

  @app :my_app

  def seed(opts \\ [], seeder \\ &PhilColumns.Seeder.run/4) do
    load_app()
    # set env with current_env/0 overwriting provided arg
    opts = Keyword.put(opts, :env, current_env())
    opts = Keyword.put(opts, :tags, [])

    opts =
      if opts[:to] || opts[:step] || opts[:all],
        do: opts,
        else: Keyword.put(opts, :all, true)

    opts =
      if opts[:log],
        do: opts,
        else: Keyword.put(opts, :log, :info)

    opts =
      if opts[:quiet],
        do: Keyword.put(opts, :log, false),
        else: opts

    for repo <- repos() do
      {:ok, _, _} = with_repo(repo, &seeder.(&1, migrations_path(&1, "seeds"), :up, opts))
    end
  end

  defp current_env do
    ## Add this to config/config.exs:
    ##
    ## config :my_app, env: config_env()
    Application.fetch_env!(@app, :env)
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
```
It can be run from the remote console or on the command line like this:
```
bin/my_app eval "MyApp.Deployment.Seeder.seed(tags: ~w(things stuff)a)"
```
