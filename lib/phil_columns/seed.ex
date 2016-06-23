defmodule PhilColumns.Seed do

  defmacro __using__(_opts) do
    quote location: :keep do
      import PhilColumns.Seed
      @disable_ddl_transaction false
      Module.register_attribute(__MODULE__, :envs, accumulate: true)
      Module.register_attribute(__MODULE__, :tags, accumulate: true)
      @before_compile PhilColumns.Seed

      defp database_operation(%{model: %{id: nil}} = changeset, repo) do
        changeset
        |> repo.insert
      end

      defp database_operation(changeset, repo) do
        changeset
        |> repo.update
      end

      def down(repo) do
      end

      def down_changeset, do: raise("Implement me")

      defp handle_up({:ok, created}, %{model: %{id: nil}}), do: {:ok, %{createds: [created]}}

      defp handle_up({:ok, updated}, %{changes: changes, model: model}) do
        changes = Enum.map(changes, fn({k,to}) -> {k, [Map.get(model, k), to]} end) |> Enum.into(%{})
        {:ok, %{updateds: [{updated, changes}]}}
      end

      defp handle_up({:error, changeset}, _), do: {:error, changeset}

      def up(repo) do
        changeset = up_changeset

        changeset
        |> database_operation(repo)
        |> handle_up(changeset)
      end

      def up_changeset, do: raise("Implement me")

      #defp repo, do: unquote(opts[:repo])

      defoverridable [
        database_operation: 2,
        down: 1,
        down_changeset: 0,
        handle_up: 2,
        up: 1,
        up_changeset: 0
      ]
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    envs = Module.get_attribute(env.module, :envs)
    tags = Module.get_attribute(env.module, :tags)

    if envs == [] do
      raise "no envs have been defined in #{inspect env.module}"
    end

    quote do
      def __seed__,
        do: [disable_ddl_transaction: @disable_ddl_transaction]

      def envs, do:
        unquote(List.flatten(envs) |> Enum.dedup |> Enum.sort)

      def tags, do:
        unquote(List.flatten(tags) |> Enum.dedup |> Enum.sort)
    end
  end

  defmacro env(env) do
    quote do
      @envs unquote(env)
    end
  end

  defmacro envs(envs) do
    quote do
      @envs unquote(envs)
    end
  end

  defmacro tag(tag) do
    quote do
      @tags unquote(tag)
    end
  end

  defmacro tags(tags) do
    quote do
      @tags unquote(tags)
    end
  end

end
