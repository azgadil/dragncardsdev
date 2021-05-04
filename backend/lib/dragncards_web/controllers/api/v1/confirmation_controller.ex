defmodule DragnCardsWeb.API.V1.ConfirmationController do
  use DragnCardsWeb, :controller
  import Ecto.Query
  alias Plug.Conn
  alias DragnCards.Repo
  alias DragnCards.Users.User

  @spec show(Conn.t(), map()) :: Conn.t()
  def show(conn, %{"id" => token}) do
    case PowEmailConfirmation.Plug.load_user_by_token(conn, token) do
      {:error, conn} ->
        conn
        |> put_status(401)
        |> json(%{error: %{status: 401, message: "Invalid confirmation code"}})

      {:ok, conn} ->
        user = conn.assigns.confirm_email_user
        confirm_time = DateTime.utc_now
        output = from(p in User, where: p.id == ^user.id, update: [set: [email_confirmed_at: ^confirm_time]])
        |> Repo.update_all([])
        |> case do
          {1, nil} ->
            conn
            |> json(%{success: %{message: "Email confirmed"}})
          _ ->
            conn
            |> put_status(500)
            |> json(%{error: %{status: 500, message: "Couldn't confirm email"}})

        end
        #IO.puts("output")
        #IO.inspect(output)
        #conn
        #|> json(%{success: %{message: "Email confirmed"}})

        # IO.puts("concont conn")
        # IO.inspect(conn)
        # conn
        # |> Pow.Plug.update_user(%{"email_confirmed_at" => DateTime.utc_now})
        # |> case do
        #   {:ok, user, conn} ->
        #     conn
        #     |> json(%{success: %{message: "Email confirmed"}})
        #   {:error, changeset, conn} ->
        #     errors = Changeset.traverse_errors(changeset, &ErrorHelpers.translate_error/1)
        #     conn
        #     |> put_status(500)
        #     |> json(%{error: %{status: 500, message: "Couldn't confirm email", errors: errors}})
        # end

    end
  end
end
