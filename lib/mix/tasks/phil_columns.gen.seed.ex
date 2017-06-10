defmodule Mix.Tasks.PhilColumns.Gen.Seed do

  use Mix.Task

  import Mix.Ecto
  import Mix.PhilColumns
  import Mix.Generator

  @shortdoc "Executes the seeds for specified env and tags down"

  def run(args) do
    no_umbrella!("phil_columns.gen.seed")
    repos = parse_repo(args)

    Enum.each repos, fn repo ->
      case OptionParser.parse(args) do
        {_, [name], _} ->
          ensure_repo(repo, args)
          path = Path.relative_to(seeds_path(repo), Mix.Project.app_path)
          file = Path.join(path, "#{timestamp()}_#{name}.exs")
          create_directory path
          create_file file, seed_template(root_mod: root_mod(repo),
            mod: Module.concat([repo, Seeds, Inflex.camelize(name)]))
        {_, _, _} ->
          Mix.raise "expected phil_columns.gen.seed to receive the seed file name, " <>
          "got: #{inspect Enum.join(args, " ")}"
      end
    end
  end

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10, do: << ?0, ?0 + i >>
  defp pad(i), do: to_string(i)

  embed_template :seed, """
  defmodule <%= inspect @mod %> do
    use <%= inspect @root_mod %>.Seed

    envs [:dev]

    def up(_repo) do
    end
  end
  """

end
