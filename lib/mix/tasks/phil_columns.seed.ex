defmodule Mix.Tasks.PhilColumns.Seed do

  use Mix.Task

  import Mix.Ecto
  import Mix.PhilColumns

  @shortdoc "Executes the seeds for specified env and tags up"

  def run(args, seeder \\ &PhilColumns.Seeder.run/4) do
    repos = parse_repo(args)
            |> List.wrap

    {opts, _, _} = OptionParser.parse args,
                     switches: [all: :boolean, step: :integer, to: :integer, quiet: :boolean,
                                pool_size: :integer, env: :string, tags: :string],
                     aliases: [e: :env, n: :step, t: :tags, v: :to]

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
      if opts[:tags],
        do: Keyword.put(opts, :tags, String.split(opts[:tags], ",") |> List.wrap |> Enum.map(fn(tag) -> String.to_atom(tag) end) |> Enum.sort),
        else: Keyword.put(opts, :tags, [])

    Enum.each repos, fn repo ->
      ensure_repo(repo, args)
      ensure_seeds_path(repo)
      {:ok, pid} = ensure_started(repo)
      seeder.(repo, seeds_path(repo), :up, opts)
      ensure_stopped(pid)
    end
  end

end
