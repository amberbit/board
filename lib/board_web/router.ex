defmodule BoardWeb.Router do
  use BoardWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    #plug :protect_from_forgery
    #plug :put_secure_browser_headers
    plug Phoenix.LiveView.Flash
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BoardWeb do
    pipe_through :browser

    get "/", PageController, :index

    post "/move/:ticket_id/to/:board_column_id", PageController, :move_to_column
    post "/move/:ticket_id/to/:board_column_id/before/:before_ticket_id", PageController, :move_to_column
  end

  # Other scopes may use custom stacks.
  # scope "/api", BoardWeb do
  #   pipe_through :api
  # end
end
