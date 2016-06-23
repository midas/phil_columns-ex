defmodule PhilColumns.Seed.Runner do

  @moduledoc false

  require Logger

  @doc """
  Runs the given seeds.
  """
  def run(repo, module, direction, operation, migrator_direction, opts) do
    log(opts[:log], "== Running #{inspect module}.#{operation}/0 #{direction}")

    run_seed(repo, module, operation, opts)
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

  defp handle_run_seed({time, {:error, %{model: %{id: nil} = model} = changeset}}, opts) do
    raise PhilColumns.SeedError,
      "Failed to create #{inspect model.__struct__} due to #{inspect changeset.errors} with changes #{inspect changeset.changes}"
  end

  defp handle_run_seed({time, {:error, %{model: model} = changeset}}, opts) do
    raise PhilColumns.SeedError,
      "Failed to update #{inspect model.__struct__} due to #{inspect changeset.errors} with changes #{inspect changeset.changes}"
  end

  defp handle_run_seed(_any, _opts) do
  end

  defp log(false, _msg), do: :ok
  defp log(level, msg),  do: Logger.log(level, msg)

end
