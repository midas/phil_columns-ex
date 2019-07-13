defmodule Mix.Tasks.PhilColumns.Seeds do

  use Mix.Task

  import Mix.Ecto
  import Mix.PhilColumns

  @shortdoc "Displays the repository seed status"
  @recursive true

  @moduledoc """
  Displays the up / down seed status for the given repository.
  The repository must be set under `:ecto_repos` in the
  current app configuration or given via the `-r` option.
  By default, seeds are expected at "priv/YOUR_REPO/seeds"
  directory of the current application but it can be configured
  by specifying the `:priv` key under the repository configuration.
  If the repository has not been started yet, one will be
  started outside our application supervision tree and shutdown
  afterwards.
  ## Examples
      mix phil_columns.seeds
      mix phil_columns.seeds -r Custom.Repo
  ## Command line options
    * `-r`, `--repo` - the repo to obtain the status for
  """

  @doc false
  def run(args, seeds \\ &PhilColumns.Seeder.seeds/3, puts \\ &IO.puts/1) do
    repos = parse_repo(args)
            |> List.wrap()

    {opts, _, _} = OptionParser.parse args,
                     switches: [env: :string, tags: :string],
                     aliases: [e: :env, t: :tags]

    opts =
      if opts[:env],
        do: Keyword.put(opts, :env, String.to_atom(opts[:env])),
        else: Keyword.put(opts, :env, :dev)

    opts =
      if opts[:tags],
        do: Keyword.put(opts, :tags, String.split(opts[:tags], ",") |> List.wrap |> Enum.map(fn(tag) -> String.to_atom(tag) end) |> Enum.sort),
        else: Keyword.put(opts, :tags, [])

    for repo <- repos do
      ensure_repo(repo, args)
      path = ensure_seeds_path(repo, opts)

      case PhilColumns.Seeder.with_repo(repo, &seeds.(&1, path, opts), [mode: :temporary]) do
        {:ok, repo_status, _} ->
          puts.(
            """

            Repo: #{inspect(repo)}

              Status    Seed ID         Seed Name
            --------------------------------------------------
            """ <>
              Enum.map_join(repo_status, "\n", fn {status, number, description} ->
                "  #{format(status, 10)}#{format(number, 16)}#{description}"
              end) <> "\n"
          )

        {:error, error} ->
          Mix.raise "Could not start repo #{inspect repo}, error: #{inspect error}"
      end
    end
  end

  defp format(content, pad) do
    content
    |> to_string()
    |> String.pad_trailing(pad)
  end

end
