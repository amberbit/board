defmodule BoardWeb.PageController do
  use BoardWeb, :controller
  import Ecto.Query, only: [from: 2]

  def index(conn, _params) do
    Phoenix.LiveView.Controller.live_render(conn, BoardWeb.LiveBoard, session: %{})
  end
end
