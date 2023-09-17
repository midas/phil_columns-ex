defmodule PhilColumns.Seed do
  defmacro __using__(_opts) do
    quote location: :keep do
      import PhilColumns.Seed
      @disable_ddl_transaction false
      Module.register_attribute(__MODULE__, :envs, accumulate: true)
      Module.register_attribute(__MODULE__, :tags, accumulate: true)
      @before_compile PhilColumns.Seed

      def down(repo) do
      end

      def up(repo) do
      end

      defoverridable down: 1,
                     up: 1
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    envs = Module.get_attribute(env.module, :envs)
    tags = Module.get_attribute(env.module, :tags)

    if envs == [] do
      raise "no envs have been defined in #{inspect(env.module)}"
    end

    quote do
      def __seed__,
        do: [disable_ddl_transaction: @disable_ddl_transaction]

      def envs, do: unquote(List.flatten(envs) |> Enum.dedup() |> Enum.sort())

      def tags, do: unquote(List.flatten(tags) |> Enum.dedup() |> Enum.sort())
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
