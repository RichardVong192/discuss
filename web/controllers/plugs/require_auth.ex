defmodule Discuss.Plugs.RequireAuth do
  import Plug.Conn
  import Phoenix.Controller

  alias Discuss.Router.Helpers

  def init(_params) do #we must declare and init function
  end

  def call(conn, _params) do #params is whatever is returned from the init function
    if conn.assigns[:user] do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in.")
      |> redirect(to: Helpers.topic_path(conn, :index))
      |> halt() #do nothing else, just send the response
    end
  end

end
