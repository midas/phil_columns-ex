defmodule PhilColumns do
  use Application

  def start(_type, _args) do
    PhilColumns.Sequence.start_link
  end
end
