defmodule Mix.Tasks.PhilColumns.Rollback do

  use Mix.Task

  import Mix.Ecto
  import Mix.PhilColumns

  @shortdoc "Executes the seeds for specified env and tags down"

  def run(args, seeder \\ &PhilColumns.Seeder.run/4) do
    repos = parse_repo(args)
            |> List.wrap

    {opts, _, _} = OptionParser.parse args,
                     switches: [all: :boolean, step: :integer, to: :integer, quiet: :boolean,
                                pool_size: :integer, env: :string],
                     aliases: [e: :env, n: :steps, v: :to]

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

    Enum.each repos, fn repo ->
      exec_task(repo, opts, fn ->
        seeder.(repo, seeds_path(repo), :down, opts)
      end)
    end
  end

end
