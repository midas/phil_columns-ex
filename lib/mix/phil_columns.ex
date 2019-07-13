defmodule Mix.PhilColumns do

  import Mix.EctoSQL

  @doc """
  Ensures the given repository's seeds path exists on the file system.
  """
  @spec ensure_seeds_path(Ecto.Repo.t, Keyword.t) :: String.t
  def ensure_seeds_path(repo, opts) do
    path = opts[:seeds_path] || Path.join(source_repo_priv(repo), "seeds")

    if not Mix.Project.umbrella? and not File.dir?(path) do
      raise_missing_seeds(Path.relative_to_cwd(path), repo)
    end

    path
  end

  defp raise_missing_seeds(path, repo) do
    Mix.raise """
    Could not find seeds directory #{inspect path}
    for repo #{inspect repo}.

    This may be because you are in a new project and the
    migration directory has not been created yet. Creating an
    empty directory at the path above will fix this error.

    If you expected existing seeds to be found, please
    make sure your repository has been properly configured
    and the configured path exists.
    """
  end

  @doc """
  Restarts the app if there was any migration command.
  """
  @spec restart_apps_if_migrated([atom], list()) :: :ok
  def restart_apps_if_migrated(_apps, []), do: :ok
  def restart_apps_if_migrated(apps, [_|_]) do
    # Silence the logger to avoid application down messages.
    Logger.remove_backend(:console)
    for app <- Enum.reverse(apps) do
      Application.stop(app)
    end
    for app <- apps do
      Application.ensure_all_started(app)
    end
    :ok
  after
    Logger.add_backend(:console, flush: true)
  end

  def root_mod(repo_mod) do
    name = repo_mod
           |> root_mod_name

    Module.concat([name])
  end

  def root_mod_name(repo_mod) do
    repo_mod
    |> Module.split
    |> List.first
  end

  #@doc """
  #Gets a path relative to the application path.
  #Raises on umbrella application.
  #"""
  #def no_umbrella!(task) do
    #if Mix.Project.umbrella? do
      #Mix.raise "cannot run task #{inspect task} from umbrella application"
    #end
  #end

  @doc """
  Gets the seeds path from a repository.
  """
  @spec seeds_path(Ecto.Repo.t) :: String.t
  def seeds_path(repo) do
    Path.join(source_repo_priv(repo), "seeds")
  end

end
