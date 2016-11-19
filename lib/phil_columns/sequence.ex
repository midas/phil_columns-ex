defmodule PhilColumns.Sequence do
  def start_link do
    Agent.start_link(fn -> Map.new end, name: __MODULE__)
  end

  def reset do
    Agent.update(__MODULE__, fn(_) -> Map.new end)
  end

  def next(sequence_name) when is_binary(sequence_name) do
    next(sequence_name, fn(n) -> sequence_name <> to_string(n) end)
  end

  def next(sequence_name) do
    raise(
      ArgumentError,
      "sequence name must be a string; got #{inspect sequence_name} instead"
    )
  end

  def next(sequence_name, formatter) do
    Agent.get_and_update(__MODULE__, fn(sequences) ->
      current_value = Map.get(sequences, sequence_name, 0)
      new_sequences = Map.put(sequences, sequence_name, current_value + 1)
      {formatter.(current_value), new_sequences}
    end)
  end
end
