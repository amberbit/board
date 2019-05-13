defmodule Board.Ticket do
  use Ecto.Schema

  schema "tickets" do
    field(:title, :string)
    field(:position, :integer)
    belongs_to(:board_column, Board.BoardColumn)
  end

  @allowed_attributes [:position, :board_column_id]

  def changeset(%Board.Ticket{} = ticket, %{} = params) do
    ticket
    |> Ecto.Changeset.cast(params, @allowed_attributes)
  end
end
