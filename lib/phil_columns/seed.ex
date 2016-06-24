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

      defp do_up({%Ecto.Changeset{} = parent_changeset, children_changesets}, repo) do
        {:ok, parent} = do_up(parent_changeset, repo)

        child_results =
          Enum.map(children_changesets, fn(child_changeset) ->
            parent_assoc_name = parent_changeset.model.__struct__.__schema__(:source)
                                |> Inflex.singularize
                                |> String.to_atom
            %{owner_key: fk_attr_name, owner: mod} = assoc_meta = child_changeset.model.__struct__.__schema__(:association, parent_assoc_name)
            model = struct(mod, Map.put(%{}, fk_attr_name, parent.id))
            child_changeset = mod.changeset(model, child_changeset.changes)
            result = do_up(child_changeset, repo)
          end)

        {:ok, parent, child_results}
      end

      defp do_up({parent, children_changesets}, repo) do
        child_results =
          Enum.map(children_changesets, fn(child_changeset) ->
            parent_assoc_name = parent.__struct__.__schema__(:source)
                                |> Inflex.singularize
                                |> String.to_atom
            %{owner_key: fk_attr_name, owner: mod} = assoc_meta = child_changeset.model.__struct__.__schema__(:association, parent_assoc_name)
            model = struct(mod, Map.put(%{}, fk_attr_name, parent.id))
            child_changeset = mod.changeset(model, child_changeset.changes)
            result = do_up(child_changeset, repo)
          end)

        {:ok, parent, child_results}
      end

      defp do_up(changeset, repo) do
        changeset
        |> database_operation(repo)
      end

      defp handle_ups(results, changesets) do
        full_results = Enum.zip(results, changesets)

        {createds, others} =
          Enum.map(full_results, fn({result, changeset}) ->
            handle_up(result, changeset)
          end)
          |> List.flatten
          |> Enum.partition(fn({op, _}) -> op == :created end)

        {updateds, others}  = Enum.partition(others, fn({op, _}) -> op == :updated end)
        {existings, others} = Enum.partition(others, fn({op, _}) -> op == :existing end)
        {errors, others}    = Enum.partition(others, fn({op, _}) -> op == :error end)

        createds  = Enum.map(createds, fn({_op, created}) -> created end)
        updateds  = Enum.map(updateds, fn({_op, {updated, changes}}) -> {updated, changes} end)
        errors    = Enum.map(errors, fn({_op, error}) -> error end)
        existings = Enum.map(existings, fn({_op, existing}) -> existing end)

        {:ok, %{createds: createds,
                errors: errors,
                existings: existings,
                updateds: updateds}}
      end

      defp handle_up({:ok, parent, child_results}, {parent_changeset, child_changesets}) do
        results = [handle_up({:ok, parent}, parent_changeset)]

        Enum.zip(child_results, child_changesets)
        |> Enum.reduce(results, fn({child_result, child_changeset},results) -> [handle_up(child_result, child_changeset)|results] end)
        |> Enum.reverse
      end

      defp handle_up({:ok, created}, %{model: %{id: nil}}) do
        {:created, created}
      end

      defp handle_up({:ok, updated}, %{changes: changes, model: model}) do
        changes = Enum.map(changes, fn({k,to}) -> {k, [Map.get(model, k), to]} end) |> Enum.into(%{})

        {:updated, {updated, changes}}
      end

      defp handle_up({:ok, parent}, %{id: id}) do
        {:existing, parent}
      end

      defp handle_up({:error, changeset}, _) do
        {:error, changeset}
      end

      defp handle_up(any, _) do
      end

      def up(repo) do
        changesets = up_changeset
                     |> List.wrap

        Enum.map(changesets, fn(changeset) ->
          changeset
          |> do_up(repo)
        end)
        |> handle_ups(changesets)
      end

      defp up_changeset, do: raise("Implement me")

      defoverridable [
        database_operation: 2,
        down: 1,
        down_changeset: 0,
        do_up: 2,
        handle_up: 2,
        handle_ups: 2,
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
