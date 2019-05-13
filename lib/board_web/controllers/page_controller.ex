defmodule BoardWeb.PageController do
  use BoardWeb, :controller
  import Ecto.Query, only: [from: 2]

  def index(conn, _params) do
    tickets_query = from ticket in Board.Ticket, order_by: [asc: :position]
    columns_query = from col in Board.BoardColumn, order_by: [asc: :position], preload: [tickets: ^tickets_query]

    columns = Board.Repo.all(columns_query)

    conn
    |> assign(:columns, columns)
    |> render("index.html")
  end

  def move_to_column(conn, %{"ticket_id" => ticket_id, "board_column_id" => board_column_id, "before_ticket_id" => before_ticket_id}) do
    tickets_query = from ticket in Board.Ticket, order_by: [asc: :position]
    column_query = from col in Board.BoardColumn, where: col.id == ^board_column_id, preload: [tickets: ^tickets_query]
    column = Board.Repo.one(column_query)

    ticket = Board.Repo.get(Board.Ticket, ticket_id)

    index = Enum.find_index(column.tickets, & "#{&1.id}" == before_ticket_id) || 0

    tickets = List.insert_at(column.tickets, index, ticket)

    tickets
    |> Enum.with_index()
    |> Enum.each(fn({ticket, position}) ->
      Board.Ticket.changeset(ticket, %{position: position, board_column_id: board_column_id}) |> Board.Repo.update!()
    end)

    index(conn |> put_layout(false), %{})
  end

  def move_to_column(conn, %{"ticket_id" => ticket_id, "board_column_id" => board_column_id}) do
    tickets_query = from ticket in Board.Ticket, order_by: [asc: :position]
    column_query = from col in Board.BoardColumn, where: col.id == ^board_column_id, preload: [tickets: ^tickets_query]
    column = Board.Repo.one(column_query)

    max_position = (column.tickets
      |> Enum.map(& &1.position)
      |> List.insert_at(0, 0)
      |> Enum.max())

    ticket = Board.Repo.get(Board.Ticket, ticket_id)

    Board.Ticket.changeset(ticket, %{position: max_position + 1, board_column_id: board_column_id}) |> Board.Repo.update!()

    index(conn |> put_layout(false), %{})
  end
end
