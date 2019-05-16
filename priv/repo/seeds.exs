# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Board.Repo.insert!(%Board.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

col1 = Board.Repo.insert!(%Board.BoardColumn{title: "To-do", position: 1})
col2 = Board.Repo.insert!(%Board.BoardColumn{title: "Doing", position: 2})
col3 = Board.Repo.insert!(%Board.BoardColumn{title: "In review", position: 3})
col4 = Board.Repo.insert!(%Board.BoardColumn{title: "Done", position: 4})

#Board.Repo.insert!(%Board.Ticket{title: "Scaffold simple Phoenix application", board_column_id: col4.id, position: 1})
#Board.Repo.insert!(%Board.Ticket{title: "Write simple REST back-end & JavaScript UI", board_column_id: col2.id, position: 1})
#Board.Repo.insert!(%Board.Ticket{title: "Upgrade to LiveView", board_column_id: col2.id, position: 1})
#Board.Repo.insert!(%Board.Ticket{title: "Refactor with OTP primitives", board_column_id: col1.id, position: 1})

Enum.map(1..1000, fn(i) ->
  Board.Repo.insert!(%Board.Ticket{title: "Ticket #{1000 - i}", board_column_id: col1.id, position: i})
end)
