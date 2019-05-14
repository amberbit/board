defmodule BoardWeb.LiveBoard do
  use Phoenix.LiveView
  import Ecto.Query, only: [from: 2]

  def render(assigns) do
    ~L"""
    <div class="row boards">
      <%= for column <- @columns do %>
        <div class="column">
          <%= live_render(@socket, BoardWeb.LiveColumn, session: %{board_column_id: column.id}, child_id: column.id) %>
        </div>
      <% end %>
    </div>
    """
  end


  def mount(_session, socket) do
    {:ok, assign(socket, columns: find_columns())}
  end

  defp find_columns() do
    columns_query = from col in Board.BoardColumn, order_by: [asc: :position]

    Board.Repo.all(columns_query)
  end
end

