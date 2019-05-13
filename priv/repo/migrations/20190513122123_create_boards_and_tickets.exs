defmodule Board.Repo.Migrations.CreateBoardsAndTickets do
  use Ecto.Migration

  def change do
    create table(:board_columns) do
      add :title, :text
      add :position, :integer
    end

    create table(:tickets) do
      add :title, :text
      add :position, :integer
      add :board_column_id, references(:board_columns)
    end
  end
end
