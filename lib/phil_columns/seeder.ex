defmodule PhilColumns.Seeder do

  require Logger

  alias PhilColumns.Seed.Runner
  alias PhilColumns.Seed.SchemaSeed

  @doc """
  Gets all migrated versions.

  This function ensures the migration table exists
  if no table has been defined yet.
  """
  @spec seeded_versions(Ecto.Repo.t) :: list()
  def seeded_versions(repo, tenant) do
    SchemaSeed.ensure_schema_seeds_table!(repo)
    SchemaSeed.seeded_versions(repo, tenant)
  end

  #@doc """
  #Runs an up migration on the given repository.

  ### Options

    #* `:log` - the level to use for logging. Defaults to `:info`.
      #Can be any of `Logger.level/0` values or `false`.
  #"""
  #@spec up(Ecto.Repo.t, integer, Module.t, Keyword.t) :: :ok | :already_up | no_return
  #def up(repo, version, module, opts \\ []) do
    #versions = migrated_versions(repo)

    #if version in versions do
      #:already_up
    #else
      #do_up(repo, version, module, opts)
      #:ok
    #end
  #end

  defp do_up(repo, version, tenant, module, opts) do
    run_maybe_in_transaction repo, module, fn ->
      attempt(repo, module, :forward, :up, :up, opts)
        || attempt(repo, module, :forward, :change, :up, opts)
        || raise PhilColumns.SeedError, message: "#{inspect module} does not implement a `up/0` function"
      SchemaSeed.up(repo, version, tenant)
    end
  end

  #@doc """
  #Runs a down migration on the given repository.

  ### Options

    #* `:log` - the level to use for logging. Defaults to `:info`.
      #Can be any of `Logger.level/0` values or `false`.

  #"""
  #@spec down(Ecto.Repo.t, integer, Module.t) :: :ok | :already_down | no_return
  #def down(repo, version, module, opts \\ []) do
    #versions = migrated_versions(repo)

    #if version in versions do
      #do_down(repo, version, module, opts)
      #:ok
    #else
      #:already_down
    #end
  #end

  defp do_down(repo, version, module, opts) do
    run_maybe_in_transaction repo, module, fn ->
      attempt(repo, module, :forward, :down, :down, opts)
        || attempt(repo, module, :backward, :change, :down, opts)
        || raise PhilColumns.SeedError, message: "#{inspect module} does not implement a `down/0` function"
      SchemaSeed.down(repo, version, tenant)
    end
  end

  defp run_maybe_in_transaction(repo, module, fun) do
    cond do
      module.__seed__[:disable_ddl_transaction] ->
        fun.()
      repo.__adapter__.supports_ddl_transaction? ->
        repo.transaction fun, [log: false, timeout: :infinity]
      true ->
        fun.()
    end
  end

  defp attempt(repo, module, direction, operation, reference, opts) do
    if Code.ensure_loaded?(module) and
       function_exported?(module, operation, 1) do
      Runner.run(repo, module, direction, operation, reference, opts)
      :ok
    end
  end

 @doc """
  Apply seeds in a directory to a repository with given strategy.

  A strategy must be given as an option.

  ## Options

    * `:all` - runs all available if `true`
    * `:step` - runs the specific number of seeds
    * `:to` - runs all until the supplied version is reached
    * `:log` - the level to use for logging. Defaults to `:info`.
      Can be any of `Logger.level/0` values or `false`.

  """
  @spec run(Ecto.Repo.t, binary, atom, Keyword.t) :: [integer]
  def run(repo, directory, direction, opts) do
    maybe_ensure_all_started(Application.get_env(:phil_columns, :ensure_all_started))

    versions = seeded_versions(repo, opts[:tenant])

    cond do
      opts[:all] ->
        run_all(repo, versions, directory, direction, opts)
      to = opts[:to] ->
        run_to(repo, versions, directory, direction, to, opts)
      #step = opts[:step] ->
        #run_step(repo, versions, directory, direction, step, opts)
      true ->
        raise ArgumentError, message: "expected one of :all, :to, or :step strategies"
    end
  end

  @doc """
  Returns an array of tuples as the seed status of the given repo,
  without actually running any seeds.
  """
  def seeds(repo, directory, opts) do
    versions = seeded_versions(repo)

    Enum.map(pending_in_direction(versions, directory, :down, opts) |> Enum.reverse, fn {a, b, _, _} ->
      {:up, a, b}
    end)
    ++
    Enum.map(pending_in_direction(versions, directory, :up, opts), fn {a, b, _, _} ->
      {:down, a, b}
    end)
  end

  #defp run_to(repo, versions, directory, direction, 0, opts) do
    #pending_in_direction(versions, directory, direction, opts)
    #|> seed(direction, repo, opts)
  #end

  defp run_to(repo, versions, directory, direction, target, opts) do
    pending_in_direction(versions, directory, direction, opts)
    |> Enum.take_while(fn(seed_info) ->
         within_target_version?(seed_info, target, direction)
       end)
    |> seed(direction, repo, opts)
  end

  defp within_target_version?({version,_,_,_}, target, :up),   do: version <= target
  defp within_target_version?({version,_,_,_}, target, :down), do: version >= target

  #defp run_step(repo, versions, directory, direction, count, opts) do
    #pending_in_direction(versions, directory, direction)
    #|> Enum.take(count)
    #|> seed(direction, repo, opts)
  #end

  defp run_all(repo, versions, directory, direction, opts) do
    pending_in_direction(versions, directory, direction, opts)
    |> seed(direction, repo, opts)
  end

  #defp pending_in_direction(versions, directory, :up) do
    #seeds_for(directory)
    #|> Enum.filter(fn {version, _name, _file} -> not (version in versions) end)
  #end

  #defp pending_in_direction(versions, directory, :down) do
    #seeds_for(directory)
    #|> Enum.filter(fn {version, _name, _file} -> version in versions end)
    #|> Enum.reverse
  #end

  defp pending_in_direction(versions, directory, :up, opts) do
    seeds_for(directory)
    |> Enum.filter(fn {version, _name, _file} -> not (version in versions) end)
    |> Enum.map(fn {version, name, file} ->
         [{mod, _bin}] = Code.compile_file(file)
         {version, name, file, mod}
       end)
    |> Enum.filter(fn {_version, _name, _file, mod} ->
         has_env_and_any_tags?(mod, opts[:env], opts[:tags])
       end)
  end

  defp pending_in_direction(versions, directory, :down, _opts) do
    seeds_for(directory)
    |> Enum.filter(fn {version, _name, _file} -> version in versions end)
    |> Enum.map(fn {version, name, file} ->
         [{mod, _bin}] = Code.compile_file(file)
         {version, name, file, mod}
       end)
    |> Enum.reverse
  end

  defp seeds_for(directory) do
    query = Path.join(directory, "*")

    for entry <- Path.wildcard(query),
        info = extract_seed_info(entry),
        do: info
  end

  defp extract_seed_info(file) do
    base = Path.basename(file)
    ext  = Path.extname(base)

    case Integer.parse(Path.rootname(base)) do
      {integer, "_" <> name} when ext == ".exs" ->
        {integer, name, file}
      _ ->
        nil
    end
  end

  defp seed(seeds, direction, repo, opts) do
    log_seeding_start(direction, opts)

    if Enum.empty? seeds do
      level = Keyword.get(opts, :log, :info)
      log(level, "Already #{direction}")
    end

    ensure_no_duplication(seeds)

    Enum.map seeds, fn {version, _name, file, mod} ->
      function_exported?(mod, :__seed__, 0) || raise_no_seed_in_file(file)

      case direction do
        :up   -> do_up(repo, version, mod, opts)
        :down -> do_down(repo, version, mod, opts)
      end

      version
    end
  end

  defp log_seeding_start(:up, opts) do
    log(opts[:log], "=== Executing seeds up for env #{inspect opts[:env]} and tags #{inspect opts[:tags]}")
  end

  defp log_seeding_start(:down, opts) do
    log(opts[:log], "=== Executing seeds down for env #{inspect opts[:env]}")
  end

  defp ensure_no_duplication([{version, name, _, _} | t]) do
    if List.keyfind(t, version, 0) do
      raise Ecto.MigrationError,
        message: "seeds can't be executed, seed version #{version} is duplicated"
    end

    if List.keyfind(t, name, 1) do
      raise Ecto.MigrationError,
        message: "seeds can't be executed, seed name #{name} is duplicated"
    end

    ensure_no_duplication(t)
  end

  defp ensure_no_duplication([]), do: :ok

  defp raise_no_seed_in_file(file) do
    raise PhilColumns.SeedError,
      message: "file #{Path.relative_to_cwd(file)} does not contain any PhilColumns.Seed"
  end

  defp has_env_and_any_tags?(mod, env, tags) do
    Enum.member?(mod.envs, env) &&
      any_intersection?(mod, tags)
  end

  defp any_intersection?(_mod, []), do: true

  defp any_intersection?(mod, tags) do
    (intersection(mod.tags, tags) |> Enum.count) > 0
  end

  defp intersection(list_a, list_b) do
    list_a -- (list_a -- list_b)
  end

  defp log(false, _msg), do: :ok
  defp log(level, msg),  do: Logger.log(level, msg)

  defp maybe_ensure_all_started(nil), do: nil

  defp maybe_ensure_all_started(apps) when is_list(apps) do
    Enum.each(apps, &Application.ensure_all_started(&1))
  end

  defp maybe_ensure_all_started(_other), do: raise "ensure_all_started must be a list of apps"

  def with_repo(repo, fun, opts \\ []) do
    config = repo.config()
    mode = Keyword.get(opts, :mode, :permanent)
    apps = [:ecto_sql | config[:start_apps_before_migration] || []]

    extra_started =
      Enum.flat_map(apps, fn app ->
        {:ok, started} = Application.ensure_all_started(app, mode)
        started
      end)

    {:ok, repo_started} = repo.__adapter__.ensure_all_started(config, mode)
    started = extra_started ++ repo_started
    pool_size = Keyword.get(opts, :pool_size, 2)

    case repo.start_link(pool_size: pool_size) do
      {:ok, _} ->
        try do
          {:ok, fun.(repo), started}
        after
          repo.stop()
        end

      {:error, {:already_started, _pid}} ->
        {:ok, fun.(repo), started}

      {:error, _} = error ->
        error
    end
  end

end
