![PhilColumns: No Fixtures Required](https://raw.githubusercontent.com/midas/phil_columns/master/readme/PhilColumns.png)

# PhilColumns

A full featured Elixir/Ecto seeding solution providing means for dev and prod seeding.


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
  ...

  def up(_repo) do
    # seeding logic ...
  end
  ...
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
  ...
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
  ...
end
```

To change the tag(s) provide them after the command command line.

    $ mix phil_columns.seed --t=users,settings,etc
    $ mix phil_columns.seed -t users,settings,etc


## Production Seeding

### Why?

Systems often have system level data that must be seeded when bootstraping a system or as new features or rolled out.  Some 
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

  def seed( opts, seeder \\ &PhilColumns.Seeder.run/4 ) do
    repos = parse_repo(opts)
            |> List.wrap

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

    Enum.each( repos, fn repo ->
      exec_task(repo, opts, fn ->
        seeder.(repo, seeds_path(repo), :up, opts)
      end)
    end)
  end
end
```

Use the module in the production app's remote console.

```elixir
Seeder.seed(tags: ~w(things stuff)a)
```

## Installation

  1. Add phil_columns to your list of dependencies in `mix.exs`:

        def deps do
          [{:phil_columns, "~> 0.1.0"}]
        end

  2. Ensure phil_columns is started before your application:

        def application do
          [applications: [:phil_columns]]
        end

