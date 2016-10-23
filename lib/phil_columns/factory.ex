defmodule PhilColumns.Factory do

  alias Ecto.Changeset

  defmacro __using__(opts) do
    quote do

      @before_compile PhilColumns.Factory
      Module.register_attribute(__MODULE__, :repo, accumulate: false)
      Module.put_attribute __MODULE__, :repo, unquote(opts[:repo])

      def build(factory_name, attrs \\ %{}) do
        PhilColumns.Factory.build(__MODULE__, factory_name, attrs)
      end

      #def build_pair(factory_name, attrs \\ %{}) do
        #PhilColumns.Factory.build_pair(__MODULE__, factory_name, attrs)
      #end

      #def build_list(number_of_factories, factory_name, attrs \\ %{}) do
        #PhilColumns.Factory.build_list(__MODULE__, factory_name, attrs)
      #end

      def insert(factory_name, attrs \\ %{}) do
        PhilColumns.Factory.insert(__MODULE__, factory_name, attrs)
      end

      def params_for(factory_name, attrs \\ %{}) do
        PhilColumns.Factory.params_for(__MODULE__, factory_name, attrs)
      end

      def factory(factory_name) do
        raise "UndefinedFactoryError: factory(:#{factory_name})"
      end

      def factory(factory_name,_) do
        raise "UndefinedFactoryError: factory(:#{factory_name}, attrs)"
      end

      defoverridable [
        factory: 1,
        factory: 2
      ]

    end
  end

  @doc false
  defmacro __before_compile__(env) do
    repo = Module.get_attribute(env.module, :repo)

    quote do
      def repo, do: unquote(repo)
    end
  end

  def build(module, factory_name, attrs \\ %{}) do
    attrs = Enum.into(attrs, %{})
    apply(module, :factory, [factory_name])
    |> handle_build( attrs )
  end

  def insert(module, factory_name, attrs \\ %{}) do
    attrs = Enum.into(attrs, %{})
    repo = module.repo
    apply(module, :factory, [factory_name])
    |> handle_insert( attrs, repo )
  end

  def params_for(module, factory_name, attrs \\ %{}) do
    attrs = Enum.into(attrs, %{})
    apply(module, :factory, [factory_name]) #|> do_merge(attrs)
    |> handle_params_for( attrs )
  end

  # Private ##########

  defp handle_build( %Changeset{} = changeset, attrs ) do
    changeset
    |> Changeset.apply_changes
    |> do_merge( attrs )
  end

  defp handle_build( %{__meta__: _} = record, attrs ) do
    record
    |> do_merge( attrs )
  end

  defp handle_insert( %Changeset{} = changeset, attrs, repo ) do
    record = changeset
             |> Changeset.apply_changes
             |> do_merge( attrs )

    schema_mod = module_from_struct( record )
    changeset  = apply( schema_mod, :changeset, [struct(schema_mod), drop_ecto_fields(record)] )

    changeset
    |> repo.insert!
  end

  defp handle_insert( %{__meta__: _} = record, attrs, repo ) do
    record
    |> do_merge( attrs )
    |> repo.insert!
  end

  defp handle_params_for( %Changeset{} = changeset, attrs ) do
    # TODO should we use Changeset.apply_changes instead?
    changeset
    |> Changeset.apply_changes
    |> do_merge( attrs )
    |> drop_ecto_fields
  end

  defp handle_params_for( %{__meta__: _} = record, attrs ) do
    record
    |> drop_ecto_fields
  end

  defp do_merge(%{__struct__: _} = record, attrs) do
    struct!(record, attrs)
  end

  defp do_merge(record, attrs) do
    Map.merge(record, attrs)
  end

  defp drop_ecto_fields(record = %{__struct__: struct, __meta__: %{__struct__: Ecto.Schema.Metadata}}) do
    record
    |> Map.from_struct
    |> Map.delete(:__meta__)
    |> Map.drop(struct.__schema__(:associations))
    |> Map.drop(struct.__schema__(:primary_key))
  end

  defp drop_ecto_fields(record) do
    raise ArgumentError, "#{inspect record} is not an Ecto model. Use `build` instead."
  end

  defp module_from_struct(%{__struct__: struct_name}) do
    struct_name
  end

  defp name_from_struct(%{__struct__: struct_name}) do
    struct_name
    |> Module.split
    |> List.last
    |> underscore
    |> String.downcase
    |> String.to_atom
  end

  defp underscore(name) do
    Regex.split(~r/(?=[A-Z])/, name)
    |> Enum.join("_")
  end

end
