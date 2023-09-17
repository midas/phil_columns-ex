defmodule PhilColumns.Seed.Runner do
  @moduledoc false

  require Logger

  @doc """
  Runs the given seeds.
  """
  def run(repo, module, direction, operation, _migrator_direction, opts) do
    log(opts[:log], "== Running #{inspect(module)}.#{operation}/0 #{direction}")

    run_seed(repo, module, operation, opts)
  end

  defp run_seed(repo, mod, operation, opts) do
    :timer.tc(mod, operation, [repo, opts])
    |> handle_run_seed(opts)
  end

  defp handle_run_seed({time, {:ok, artifacts}}, opts) do
    createds = Map.get(artifacts, :createds, [])
    updateds = Map.get(artifacts, :updateds, [])
    errors = Map.get(artifacts, :errors, [])
    existings = Map.get(artifacts, :existings, [])

    Enum.each(existings, fn existing ->
      log(
        opts[:log],
        "Existing parent #{inspect(existing.__struct__)}{id: #{inspect(existing.id)}}"
      )
    end)

    Enum.each(createds, fn created ->
      log(opts[:log], "Created #{inspect(created.__struct__)}{id: #{inspect(created.id)}}")
    end)

    Enum.each(updateds, fn {updated, changes} ->
      log(
        opts[:log],
        "Updated #{inspect(updated.__struct__)}{id: #{inspect(updated.id)}} with changes: #{
          inspect(changes)
        }"
      )
    end)

    Enum.each(errors, fn changeset ->
      log(
        opts[:log],
        "ERROR #{inspect(changeset.errors)} on #{changeset.model.__struct__}{id: #{
          inspect(changeset.model.id)
        }} with changes #{inspect(changeset.changes)}"
      )
    end)

    if Enum.count(errors) > 0, do: raise("failed due to errors")

    log(opts[:log], "== Seeded in #{inspect(div(time, 10000) / 10)}s")
  end

  defp handle_run_seed({_time, {:error, %{model: %{id: nil} = model} = changeset}}, _opts) do
    raise PhilColumns.SeedError,
          "Failed to create #{inspect(model.__struct__)} due to #{inspect(changeset.errors)} with changes #{
            inspect(changeset.changes)
          }"
  end

  defp handle_run_seed({_time, {:error, %{model: model} = changeset}}, _opts) do
    raise PhilColumns.SeedError,
          "Failed to update #{inspect(model.__struct__)} due to #{inspect(changeset.errors)} with changes #{
            inspect(changeset.changes)
          }"
  end

  defp handle_run_seed(_any, _opts) do
  end

  defp log(false, _msg), do: :ok
  defp log(level, msg), do: Logger.log(level, msg)
end
