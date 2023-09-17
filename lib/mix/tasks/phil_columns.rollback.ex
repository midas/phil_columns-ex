defmodule Mix.Tasks.PhilColumns.Rollback do
  use Mix.Task

  import Mix.Ecto
  import Mix.PhilColumns

  @shortdoc "Executes the seeds for specified env and tags down"

  def run(args, seeder \\ &PhilColumns.Seeder.run/4) do
    repos =
      parse_repo(args)
      |> List.wrap()

    {opts, _, _} =
      OptionParser.parse(args,
        switches: [
          all: :boolean,
          step: :integer,
          to: :integer,
          quiet: :boolean,
          pool_size: :integer,
          env: :string,
          tenant: :string
        ],
        aliases: [e: :env, n: :steps, v: :to]
      )

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

    opts =
      if opts[:env],
        do: Keyword.put(opts, :env, String.to_atom(opts[:env])),
        else: Keyword.put(opts, :env, :dev)

    opts =
      if opts[:tenant],
        do: opts,
        else: Keyword.put(opts, :tenant, "main")

    # Start ecto_sql explicitly before as we don't need
    # to restart those apps if migrated.
    {:ok, _} = Application.ensure_all_started(:ecto_sql)

    for repo <- repos do
      ensure_repo(repo, args)
      path = ensure_seeds_path(repo, opts)

      pool = repo.config[:pool]

      fun =
        if Code.ensure_loaded?(pool) and function_exported?(pool, :unboxed_run, 2) do
          &pool.unboxed_run(&1, fn -> seeder.(&1, path, :down, opts) end)
        else
          &seeder.(&1, path, :down, opts)
        end

      case PhilColumns.Seeder.with_repo(repo, fun, [mode: :temporary] ++ opts) do
        {:ok, migrated, apps} ->
          restart_apps_if_migrated(apps, migrated)

        {:error, error} ->
          Mix.raise("Could not start repo #{inspect(repo)}, error: #{inspect(error)}")
      end
    end
  end
end
