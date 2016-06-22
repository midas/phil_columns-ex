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

  @doc """
  Gets the seeds path from a repository.
  """
  @spec seeds_path(Ecto.Repo.t) :: String.t
  def seeds_path(repo) do
    Path.join(repo_priv(repo), "seeds")
  end

end
