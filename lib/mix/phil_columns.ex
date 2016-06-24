defmodule Mix.PhilColumns do

  import Mix.Ecto

  @doc """
  Ensures the given repository's seeds path exists on the filesystem.
  """
  @spec ensure_seeds_path(Ecto.Repo.t) :: Ecto.Repo.t | no_return
  def ensure_seeds_path(repo) do
    #with false <- Mix.Project.umbrella?,
         #path = Path.relative_to(seeds_path(repo), Mix.Project.app_path),
         #false <- File.dir?(path),
         #do: Mix.raise "Could not find seeds directory #{inspect path} for repo #{inspect repo}"
    #repo

    path = Path.relative_to(seeds_path(repo), Mix.Project.app_path)
    unless Mix.Project.umbrella? do
      unless File.dir?(path) do
        Mix.raise "Could not find seeds directory #{inspect path} for repo #{inspect repo}"
      end
    else
      Mix.raise "Could not find seeds directory #{inspect path} for repo #{inspect repo}"
    end

    repo
  end

  def exec_task(repo, opts, task) do
    ensure_repo(repo, opts)
    ensure_seeds_path(repo)
    {:ok, pid} = ensure_started(repo)
    result = task.()
    pid && ensure_stopped(pid)
    result
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
    Path.join(repo_priv(repo), "seeds")
  end

end
