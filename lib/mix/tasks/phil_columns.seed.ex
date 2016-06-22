defmodule Mix.Tasks.PhilColumns.Seed do

  use Mix.Task

  import Mix.Ecto
  import Mix.PhilColumns

  @shortdoc "Executes the seeds for specified env and tags up"

  def run(args, seeder \\ &PhilColumns.Seeder.run/4) do
    repos = parse_repo(args)
            |> List.wrap
    #IO.inspect repos

    {opts, _, _} = OptionParser.parse args,
                     switches: [all: :boolean, step: :integer, to: :integer, quiet: :boolean,
                                pool_size: :integer],
                     aliases: [n: :step, v: :to]

    opts =
      if opts[:to] || opts[:step] || opts[:all],
        do: opts,
        else: Keyword.put(opts, :all, true)

    opts =
      if opts[:quiet],
        do: Keyword.put(opts, :log, false),
        else: opts

    #IO.inspect opts

    Enum.each repos, fn repo ->
      ensure_repo(repo, args)
      ensure_seeds_path(repo)
      {:ok, pid} = ensure_started(repo)
      IO.inspect pid
      seeder.(repo, migrations_path(repo), :up, opts)
      ensure_stopped(pid)
    end
  end

end
