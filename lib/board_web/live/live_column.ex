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

  def mount(%{board_column_id: id}, socket) do
    # when LiveView mounts, subscribe immediatelly to Phoenix.PubSub
    # so whenever the column updates, we get notified and receive
    # %BoardColumn{} with updated list of Tickets
    Phoenix.PubSub.subscribe(Board.PubSub, self, "board_columns:#{id}")

    {:ok, assign(socket, column: find_column(id))}
  end

  # Whenever someone posts updated column/tickets data over PubSub
  # let's update our local copy and re-render
  def handle_info({:updated, %{column: column}}, socket) do
    {:noreply, assign(socket, column: column)}
  end

  # Ticket was dropped at current column, at the end of the list. We don't
  # need to re-number the tickets, just move the dropped one here at the end
  def handle_event(%{"before_ticket_id" => nil, "column_id" => board_column_id, "ticket_id" => ticket_id}, _val, %{assigns: %{column: column}} = socket) do
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

  # Ticket was dropped at current column, before some other ticket
  # We are moving the ticket to this column, and re-number positions
  # of all the tickets in the column.
  #
  # Note: this can be done smarter
  def handle_event(%{"before_ticket_id" => before_ticket_id, "column_id" => board_column_id, "ticket_id" => ticket_id}, _val, %{assigns: %{column: column}} = socket) do
    ticket = Board.Repo.get(Board.Ticket, ticket_id)

    index = Enum.find_index(column.tickets, & "#{&1.id}" == before_ticket_id) || 0

    tickets = List.insert_at(column.tickets, index, ticket)

    tickets
    |> Enum.with_index()
    |> Enum.each(fn({ticket, position}) ->
      # this is prety naive but ok for now
      Board.Ticket.changeset(ticket, %{position: position, board_column_id: board_column_id}) |> Board.Repo.update!()
    end)

    [ticket.board_column_id, socket.assigns.column.id]
    |> Enum.uniq()
    |> update_live_columns()

    {:noreply, socket}
  end

  # Updates affected columns, sending them updated data over PubSub.
  # For each affected column (dragged from and to) it loads up the data
  # from database and fires up the PubSub event.
  defp update_live_columns(column_ids), do: column_ids |> Enum.each(& update_live_column(&1))

  defp update_live_column(column_id) do
    Phoenix.PubSub.broadcast(Board.PubSub, "board_columns:#{column_id}", {:updated, %{column: find_column(column_id)}})
  end

  # Load up data from database for the column of given ID
  defp find_column(id) do
    tickets_query = from ticket in Board.Ticket, order_by: [asc: :position]
    column_query = from col in Board.BoardColumn, where: col.id == ^id, order_by: [asc: :position], preload: [tickets: ^tickets_query]

    Board.Repo.one(column_query)
  end
end
