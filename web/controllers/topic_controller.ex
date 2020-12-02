defmodule Discuss.TopicController do
  use Discuss.Web, :controller
  alias Discuss.Topic

  plug(Discuss.Plugs.RequireAuth when action in [:new, :create, :edit, :update, :delete])
  plug :check_topic_owner when action in [:update, :edit, :delete]

  def index(conn, _params) do
    IO.inspect(conn.assigns)
    topics = Repo.all(Topic)
    render(conn, "index.html", topics: topics)
  end

  def show(conn, %{"id" => topic_id}) do
    topic = Repo.get!(Topic, topic_id)
    render conn, "show.html", topic: topic
  end

  def new(conn, _params) do
    changeset = Topic.changeset(%Topic{}, %{})

    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"topic" => topic}) do
    changeset = Topic.changeset(%Topic{}, topic)

    # Take the current user from our connection object
    changeset =
      conn.assigns.user
      # Pass the user into the build_assoc which produces a topic struct
      |> build_assoc(:topics)
      # Pipe topic struct into Topic.changeset function. The struct that was piped in had a reference to the current user.
      |> Topic.changeset(topic)

    # The topic created now has a built in reference to the current user
    # Then take the changeset and put it into our database using the following code below

    case Repo.insert(changeset) do
      {:ok, post} ->
        conn
        # put_flash shows 1 time messages to our users
        |> put_flash(:info, "Topic Created")
        # redirect to a path, specifically calling a function
        |> redirect(to: topic_path(conn, :index))

      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  # event handler gets called with the topic id that we are trying to change
  def edit(conn, %{"id" => topic_id}) do
    # pull that topic id out of the database using the Repo.get helper. Takes the type of the argument and the id of the record
    topic = Repo.get(Topic, topic_id)
    # make a changset out of that topic from the database
    changeset = Topic.changeset(topic)
    # this is because the form helps expect to recieve a changeset from the databse

    # add in the topic itself because when we submit the form we need to check that we are submiting to the correct route
    # so we pass in the entire topic to generate the correct path
    render(conn, "edit.html", changeset: changeset, topic: topic)
  end

  def update(conn, %{"id" => topic_id, "topic" => topic}) do
    # (struct, new attributes that we want to apply to the struct), result is an object describing how we are going to migrate the old topic to the new record
    old_topic = Repo.get(Topic, topic_id)
    changeset = Repo.get(Topic, topic_id) |> Topic.changeset(topic)

    case Repo.update(changeset) do
      {:ok, _topic} ->
        conn
        |> put_flash(:info, "Topic Updated")
        |> redirect(to: topic_path(conn, :index))

      {:error, changeset} ->
        render(conn, "edit.html", changeset: changeset, topic: old_topic)
    end
  end

  def delete(conn, %{"id" => topic_id}) do
    Repo.get!(Topic, topic_id) |> Repo.delete!()

    conn
    |> put_flash(:info, "Topic Deleted")
    |> redirect(to: topic_path(conn, :index))
  end

  def check_topic_owner(conn, _params) do #_params is not a data from the router or form, to get access from the params object, you must  do pattern matching
    %{params: %{"id" => topic_id}} = conn

    if Repo.get(Topic, topic_id).user_id == conn.assigns.user.id do
      conn
    else
      conn
      |> put_flash(:error, "You cannot edit that")
      |> redirect(to: topic_path(conn, :index))
      |> halt()
    end
  end
end
