defmodule BoardWeb.LiveColumn do
  use Phoenix.LiveView
  import Ecto.Query, only: [from: 2]

  def render(assigns) do
    ~L"""
    <div class="board-column dropzone" data-column-id="<%= @column.id %>">
      <h4><%= @column.title %></h4>

      <div class="board-tickets dropzone">
        <%= for ticket <- @column.tickets do %>
          <div class="ticket" data-ticket-id="<%= ticket.id %>">
            <div class="drop-ghost"></div>
            <h5 draggable="true" data-ticket-id="<%= ticket.id %>" class="ticket-title"><%= ticket.title %></h5>
          </div>
        <% end %>

        <div class="drop-ghost"></div>
      </div>
    </div>
    """
  end

  def handle_event(%{"before_ticket_id" => nil, "column_id" => board_column_id, "ticket_id" => ticket_id}, _val, socket) do
    tickets_query = from ticket in Board.Ticket, order_by: [asc: :position]
    column_query = from col in Board.BoardColumn, where: col.id == ^board_column_id, preload: [tickets: ^tickets_query]
    column = Board.Repo.one(column_query)

    max_position = (column.tickets
      |> Enum.map(& &1.position)
      |> List.insert_at(0, 0)
      |> Enum.max())

    ticket = Board.Repo.get(Board.Ticket, ticket_id)

    Board.Ticket.changeset(ticket, %{position: max_position + 1, board_column_id: board_column_id}) |> Board.Repo.update!()

    [ticket.board_column_id, socket.assigns.column.id]
    |> Enum.uniq()
    |> update_live_columns()

    {:noreply, socket}
  end

  def handle_event(%{"before_ticket_id" => before_ticket_id, "column_id" => board_column_id, "ticket_id" => ticket_id}, _val, socket) do
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

    [ticket.board_column_id, socket.assigns.column.id]
    |> Enum.uniq()
    |> update_live_columns()

    {:noreply, socket}
  end

  def mount(%{board_column_id: id}, socket) do
    column = %{tickets: tickets} = find_column(id)

    Phoenix.PubSub.subscribe(Board.PubSub, self, "board_columns:#{id}")

    {:ok, assign(socket, column: column)}
  end

  def handle_info({:updated, %{column: column}}, socket) do
    {:noreply, assign(socket, column: column)}
  end

  defp find_column(id) do
    tickets_query = from ticket in Board.Ticket, order_by: [asc: :position]
    column_query = from col in Board.BoardColumn, where: col.id == ^id, order_by: [asc: :position], preload: [tickets: ^tickets_query]

    Board.Repo.one(column_query)
  end

  defp update_live_columns(column_ids), do: column_ids |> Enum.each(& update_live_column(&1))

  defp update_live_column(column_id) do
    column = find_column(column_id)

    Phoenix.PubSub.broadcast(Board.PubSub, "board_columns:#{column_id}", {:updated, %{column: column}})
  end
end
