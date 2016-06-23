defmodule PhilColumns.Seed.Runner do

  @moduledoc false

  require Logger

  @doc """
  Runs the given seeds.
  """
  def run(repo, module, direction, operation, migrator_direction, opts) do
    log(opts[:log], "== Running #{inspect module}.#{operation}/0 #{direction}")
    #log(opts[:log], "     #{inspect module.envs} #{inspect module.tags}")

    Enum.member?(module.envs, opts[:env])
    |> run_if_configured_for_env(repo, module, operation, opts)
  end

  defp run_seed(repo, mod, operation, opts) do
    :timer.tc(mod, operation, [repo])
    |> handle_run_seed(opts)
  end

  defp handle_run_seed({time, {:ok, artifacts}}, opts) do
    createds = Map.get( artifacts, :createds, [] )
    updateds = Map.get( artifacts, :updateds, [] )

    Enum.each(createds, fn(created) ->
      log(opts[:log], "Created #{inspect created.__struct__}{id: #{inspect created.id}}")
    end)

    Enum.each(updateds, fn({updated, changes}) ->
      log(opts[:log], "Updated #{inspect updated.__struct__}{id: #{inspect updated.id}} with changes: #{inspect changes}")
    end)

    log(opts[:log], "== Seeded in #{inspect(div(time, 10000) / 10)}s")
  end

  defp handle_run_seed({time, {:error, changeset}}, opts) do
  end

  #defp handle_run_seed(any, opts) do
    #require IEx; IEx.pry
  #end

  defp run_if_configured_for_env(true, repo, mod, operation, opts) do
    run_if_tagged(opts[:tags], repo, mod, operation, opts)
  end

  defp run_if_configured_for_env(false, repo, mod, operation, opts), do: log(opts[:log], "SKIP due to env")

  defp run_if_tagged([], repo, mod, operation, opts) do
    # no tags infers all seeds
    run_seed(repo, mod, operation, opts)
  end

  defp run_if_tagged(tags, repo, mod, operation, opts) do
    ((intersection(mod.tags, opts[:tags]) |> Enum.count) > 0)
    |> do_run_if_tagged(repo, mod, operation, opts)
  end

  defp do_run_if_tagged(true, repo, mod, operation, opts) do
    run_seed(repo, mod, operation, opts)
  end

  defp do_run_if_tagged(false, _repo, _mod, _operation, opts), do: log(opts[:log], "SKIP due to tags")

      #cond do
        #Enum.member?(mod.envs, opts[:env]) ->
          #cond do
            #intersection(mod.tags, opts[:tags]) |> Enum.count > 0 ->
              #case direction do
                #:up   -> do_up(repo, version, mod, opts)
                #:down -> do_down(repo, version, mod, opts)
              #end
            #true ->
              #IO.puts("SKIP due to tags")
          #end
        #true ->
          #IO.puts("SKIP due to env")
      #end

  defp intersection(list_a, list_b) do
    list_a -- (list_a -- list_b)
  end

  defp log(false, _msg), do: :ok
  defp log(level, msg),  do: Logger.log(level, msg)

end
