defmodule SpadesGame.GameUI do
  @moduledoc """
  One level on top of Game.
  """

  alias SpadesGame.{Game, GameOptions, GameUI, GameUISeat, Groups, Group, Stack, Card, User}

  @derive Jason.Encoder
  defstruct [
    :game,
    :game_name,
    :options,
    :created_at,
    :created_by,
    :seats,
    :groups,
    :first_player,
    :player1,
    :player2,
    :player3,
    :player4,
    :round_number
  ]

  use Accessible

  @type t :: %GameUI{
          game: Game.t(),
          game_name: String.t(),
          options: GameOptions.t(),
          created_at: DateTime.t(),
          created_by: User.t(),
          seats: %{
            player1: GameUISeat.t(),
            player2: GameUISeat.t(),
            player3: GameUISeat.t(),
            player4: GameUISeat.t()
          },
          groups: Map.t(),
          first_player: 1 | 2 | 3 | 4,
          player1: GamePlayer.t(),
          player2: GamePlayer.t(),
          player3: GamePlayer.t(),
          player4: GamePlayer.t(),
          round_number: integer,
        }

  @spec new(String.t(), User.t(), GameOptions.t()) :: GameUI.t()
  def new(game_name, user, %GameOptions{} = options) do
    game = Game.new(game_name, options)
    IO.puts("gameui new")
    IO.inspect(game)

    %GameUI{
      game: game,
      game_name: game_name,
      options: options,
      created_at: DateTime.utc_now(),
      created_by: user,
      seats: %{
        player1: GameUISeat.new_blank(),
        player2: GameUISeat.new_blank(),
        player3: GameUISeat.new_blank(),
        player4: GameUISeat.new_blank()
      },
      groups: Groups.new(),
      first_player: 1,
      player1: nil,
      player2: nil,
      player3: nil,
      player4: nil,
      round_number: 1,
    }
  end

  # @doc """
  # censor_hands/1: Return a version of GameUI with all hands hidden.
  # """
  # @spec censor_hands(GameUI.t()) :: GameUI.t()
  # def censor_hands(gameui) do
  #   gameui
  #   |> put_in([:game, :player1, :hand], [])
  #   |> put_in([:game, :player2, :hand], [])
  #   |> put_in([:game, :player3, :hand], [])
  #   |> put_in([:game, :player4, :hand], [])
  # end

  @doc """
  update_groups/3: A player moves a card on the table.
  """
  @spec update_groups(GameUI.t(), number, Groups.t()) :: GameUI.t() #DragEvent.t()) :: GameUI.t()
  def update_groups(game_ui, user_id, groups) do
    %{game_ui |
      groups: groups
    }
  end

  @doc """
  update_card/6: A player moves a card on the table.
  """
  @spec update_card(GameUI.t(), number, Card.t(), String.t(), number, number) :: GameUI.t() #DragEvent.t()) :: GameUI.t()
  def update_card(game_ui, user_id, card, group_id, stack_index, card_index) do
    IO.puts("game_ui: update_card a")
    case Game.update_card(game_ui.game, user_id, card, group_id, stack_index, card_index) do
      {:ok, new_game} ->
        %{game_ui | game: new_game}

      {:error, _msg} ->
        game_ui
    end
  end

  @doc """
  toggle_exhaust/3: A player moves a card on the table.
  """
  @spec toggle_exhaust(GameUI.t(), number, Group.t(), Stack.t(), Card.t()) :: GameUI.t() #DragEvent.t()) :: GameUI.t()
  def toggle_exhaust(game_ui, user_id, group, stack, card) do
    IO.puts("game_ui: toggle_exhaust a")
    case Game.toggle_exhaust(game_ui.game, user_id, group, stack, card) do
      {:ok, new_game} ->
        %{game_ui | game: new_game}

      {:error, _msg} ->
        game_ui
    end
  end

  # @doc """
  # user_id_to_seat/2: Which seat is this user sitting in?
  # If :bot, check if the active turn seat belongs to a bot, return that seat if so.
  # """
  # @spec user_id_to_seat(GameUI.t(), number | :bot) :: nil | :west | :east | :north | :south
  # def user_id_to_seat(%GameUI{game: %Game{turn: turn}} = game_ui, :bot) do
  #   if bot_turn?(game_ui), do: turn, else: nil
  # end

  def user_id_to_seat(game_ui, user_id) do
    game_ui.seats
    |> Map.new(fn {k, %GameUISeat{} = v} -> {v.sitting, k} end)
    |> Map.delete(nil)
    |> Map.get(user_id)
  end

  @doc """
  sit/3: User is attempting to sit in a seat.
  Let them do it if no one is in the seat, and they are not
  in any other seats.  Otherwise return the game unchanged.
  --> sit(gameui, userid, which_seat)
  """
  @spec sit(GameUI.t(), integer, String.t()) :: GameUI.t()
  def sit(gameui, userid, "player1"), do: do_sit(gameui, userid, :player1)
  def sit(gameui, userid, "player2"), do: do_sit(gameui, userid, :player2)
  def sit(gameui, userid, "player3"), do: do_sit(gameui, userid, :player3)
  def sit(gameui, userid, "player4"), do: do_sit(gameui, userid, :player4)
  def sit(gameui, _userid, _), do: gameui

  @spec do_sit(GameUI.t(), integer, :player1 | :player2 | :player3 | :player4) :: GameUI.t()
  defp do_sit(gameui, userid, which) do
    if sit_allowed?(gameui, userid, which) do
      seat = gameui.seats[which] |> GameUISeat.sit(userid)
      seats = gameui.seats |> Map.put(which, seat)

      %GameUI{gameui | seats: seats}
    else
      gameui
    end
  end

  # Is this user allowed to sit in this seat?
  @spec sit_allowed?(GameUI.t(), integer, :player1 | :player2 | :player3 | :player4) :: boolean
  defp sit_allowed?(gameui, userid, which) do
    !already_sitting?(gameui, userid) && seat_empty?(gameui, which)
  end

  # Is this user sitting in a seat?
  @spec seat_empty?(GameUI.t(), integer) :: boolean
  defp already_sitting?(gameui, userid) do
    gameui.seats
    |> Map.values()
    |> Enum.map(fn %GameUISeat{} = seat -> seat.sitting end)
    |> Enum.member?(userid)
  end

  # Is this seat empty?
  @spec seat_empty?(GameUI.t(), :player1 | :player2 | :player3 | :player4) :: boolean
  defp seat_empty?(gameui, which), do: gameui.seats[which].sitting == nil

  @doc """
  leave/2: Userid just left the table.  If they were seated, mark
  their seat as vacant.
  """
  @spec leave(GameUI.t(), integer) :: GameUI.t()
  def leave(gameui, userid) do
    seats =
      for {k, v} <- gameui.seats,
          into: %{},
          do: {k, if(v.sitting == userid, do: GameUISeat.new_blank(), else: v)}

    %{gameui | seats: seats}
  end

  @doc """
  check_full_seats/1
  When the last person sits down and all of the seats are full, put a timestamp
  on ".when_seats_full".
  If there is a timestamp set, and someone just stood up, clear the timestamp.
  """
  @spec check_full_seats(GameUI.t()) :: GameUI.t()
  def check_full_seats(%GameUI{} = gameui) do
    cond do
      everyone_sitting?(gameui) and gameui.when_seats_full == nil ->
        %{gameui | when_seats_full: DateTime.utc_now()}

      not everyone_sitting?(gameui) and gameui.when_seats_full != nil ->
        %{gameui | when_seats_full: nil}

      true ->
        gameui
    end
  end

  @doc """
  check_game/1:
  Run the series of checks on the Game object.
  Similar to GameUI's checks(), but running on the embedded
  game_ui.game object/level instead.
  """
  @spec check_game(GameUI.t()) :: GameUI.t()
  def check_game(%GameUI{} = game_ui) do
    {:ok, game} = Game.checks(game_ui.game)
    %GameUI{game_ui | game: game}
  end

  @doc """
  everyone_sitting?/1:
  Does each seat have a person sitting in it?
  """
  @spec everyone_sitting?(GameUI.t()) :: boolean
  def everyone_sitting?(gameui) do
    [:player1, :player2, :player3, :player4]
    |> Enum.reduce(true, fn seat, acc ->
      acc and gameui.seats[seat].sitting != nil
    end)
  end

  @doc """
  trick_full?/1:
  Does the game's current trick have one card for each player?
  """
  @spec trick_full?(GameUI.t()) :: boolean
  def trick_full?(game_ui) do
    Game.trick_full?(game_ui.game)
  end

  @spec rewind_trickfull_devtest(GameUI.t()) :: GameUI.t()
  def rewind_trickfull_devtest(game_ui) do
    %GameUI{game_ui | game: Game.rewind_trickfull_devtest(game_ui.game)}
  end

  @doc """
  invite_bots/1: Invite bots to sit on the remaining seats.
  """
  @spec invite_bots(GameUI.t()) :: GameUI.t()
  def invite_bots(game_ui) do
    game_ui
    |> map_seats(fn seat ->
      GameUISeat.bot_sit_if_empty(seat)
    end)
  end

  @doc """
  bots_leave/1: Bots have left the table (server terminated).
  """
  @spec bots_leave(GameUI.t()) :: GameUI.t()
  def bots_leave(game_ui) do
    game_ui
    |> map_seats(fn seat ->
      GameUISeat.bot_leave_if_sitting(seat)
    end)
  end

  @doc """
  map_seats/2: Apply a 1 arity function to all seats
  should probably only be used internally
  """
  @spec map_seats(GameUI.t(), (GameUISeat.t() -> GameUISeat.t())) :: GameUI.t()
  def map_seats(game_ui, f) do
    seats =
      game_ui.seats
      |> Enum.map(fn {where, seat} -> {where, f.(seat)} end)
      |> Enum.into(%{})

    %GameUI{game_ui | seats: seats}
  end

  @doc """
  bot_turn?/1 : Is it currently a bot's turn?
  """
  # @spec bot_turn?(GameUI.t()) :: boolean
  # def bot_turn?(%GameUI{game: %Game{winner: winner}}) when winner != nil, do: false
  # def bot_turn?(%GameUI{game: %Game{turn: nil}}), do: false

  # def bot_turn?(%GameUI{game: %Game{turn: turn}, seats: seats}) do
  #   seats
  #   |> Map.get(turn)
  #   |> GameUISeat.is_bot?()
  # end
end
