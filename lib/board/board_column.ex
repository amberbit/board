defmodule Board.BoardColumn do
  use Ecto.Schema

  schema "board_columns" do
    field(:title, :string)
    field(:position, :integer)

    has_many(:tickets, Board.Ticket)
  end
end
