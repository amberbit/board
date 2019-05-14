defmodule BoardWeb.LiveBoard do
  use Phoenix.LiveView
  import Ecto.Query, only: [from: 2]

  def render(assigns) do
    ~L"""
    <div class="row boards">
      <%= for column <- @columns do %>
        <div class="column">
          <div class="board-column dropzone" data-column-id="<%= column.id %>">
            <h4><%= column.title %></h4>

            <div class="board-tickets dropzone">
              <%= for ticket <- column.tickets do %>
                <div class="ticket" data-ticket-id="<%= ticket.id %>">
                  <div class="drop-ghost"></div>
                  <h5 draggable="true" data-ticket-id="<%= ticket.id %>" class="ticket-title"><%= ticket.title %></h5>
                </div>
              <% end %>

              <div class="drop-ghost"></div>
            </div>
          </div>
        </div>
      <% end %>
    </div>

    """
  end


  def mount(_session, socket) do
    {:ok, assign(socket, columns: find_columns())}
  end

  defp find_columns() do
    tickets_query = from ticket in Board.Ticket, order_by: [asc: :position]
    columns_query = from col in Board.BoardColumn, order_by: [asc: :position], preload: [tickets: ^tickets_query]

    Board.Repo.all(columns_query)
  end

  def handle_event(%{"before_ticket_id" => nil, "column_id" => board_column_id, "ticket_id" => ticket_id}, _value, socket) do
    tickets_query = from ticket in Board.Ticket, order_by: [asc: :position]
    column_query = from col in Board.BoardColumn, where: col.id == ^board_column_id, preload: [tickets: ^tickets_query]
    column = Board.Repo.one(column_query)

    max_position = (column.tickets
      |> Enum.map(& &1.position)
      |> List.insert_at(0, 0)
      |> Enum.max())

    ticket = Board.Repo.get(Board.Ticket, ticket_id)

    Board.Ticket.changeset(ticket, %{position: max_position + 1, board_column_id: board_column_id}) |> Board.Repo.update!()

    {:noreply, assign(socket, columns: find_columns())}
  end

  def handle_event(%{"before_ticket_id" => before_ticket_id, "column_id" => board_column_id, "ticket_id" => ticket_id}, _value, socket) do
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

    {:noreply, assign(socket, columns: find_columns())}
  end
end

