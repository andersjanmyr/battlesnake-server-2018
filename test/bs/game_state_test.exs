defmodule Bs.GameStateTest do
  alias Bs.Case
  alias Bs.GameState

  use Case, async: false

  @state %GameState{world: 10, hist: [9, 8, 7]}
  @prev %GameState{world: 9, hist: [8, 7]}
  @empty_state %GameState{world: 1, hist: []}

  def ping(pid), do: &send(pid, {:ping, &1})

  describe "#set_winners(t) when everyone is dead" do
    test "sets the winner to whoever died last" do
      world =
        build(
          :world,
          snakes: [],
          dead_snakes: [
            build(:snake, id: 3) |> kill_snake(1),
            build(:snake, id: 2) |> kill_snake(2),
            build(:snake, id: 1) |> kill_snake(2)
          ]
        )

      state = build(:state, world: world)
      state = GameState.set_winners(state)
      assert state.winners == MapSet.new([1, 2])
    end
  end

  describe "#set_winners(t)" do
    test "sets the winner to anyone that is still alive" do
      world =
        build(
          :world,
          snakes: [build(:snake, id: 1)],
          dead_snakes: [
            build(:snake, id: 2) |> kill_snake(1)
          ]
        )

      state = build(:state, world: world)
      state = GameState.set_winners(state)
      assert state.winners == MapSet.new([1])
    end
  end

  describe "#step_back/1" do
    test "does nothing when the history is empty" do
      assert GameState.step_back(@empty_state) == @empty_state
    end

    test "rewinds the state to the last move" do
      assert GameState.step_back(@state) == @prev
    end
  end

  describe "#step(t)" do
    test "doesn't set the winner" do
      snake = build(:snake)
      world = build(:world, snakes: [snake])
      state = build(:state, world: world, objective: fn _ -> false end)
      state = GameState.step(state)
      assert state.winners == []
    end
  end

  describe "#step(t) when the game is done" do
    setup do
      snake = build(:snake)
      world = build(:world, snakes: [snake])
      state = build(:state, world: world, objective: fn _ -> true end)
      state = GameState.step(state)

      [state: state, snake: snake]
    end

    test "sets the winner if the game is done", c do
      assert c.state.winners == MapSet.new([c.snake.id])
    end

    test "sends a message to itself to save the winner" do
      assert_receive :game_done
    end
  end

  describe "#step(%{status: :replay})" do
    test "halts the game if the history is empty" do
      state = GameState.replay!(build(:state, hist: []))
      new_state = GameState.step(state)
      assert new_state == GameState.halted!(state)
    end

    test "steps forwards to the next turn" do
      hist = for t <- 0..3, do: build(:world, turn: t)
      state = GameState.replay!(build(:state, hist: hist))
      state = GameState.step(state)

      [h | hist] = hist

      assert state.world == h
      assert state.hist == hist
    end
  end

  for status <- GameState.statuses() do
    method = "#{status}!"

    test "##{method}/1" do
      assert GameState.unquote(:"#{method}")(@state).status == unquote(status)
    end

    method = "#{status}?"

    test "##{method}/1" do
      state = put_in(@state.status, unquote(status))
      assert GameState.unquote(:"#{method}")(state) == true

      state = put_in(@state.status, :__fake_state__)
      assert GameState.unquote(:"#{method}")(state) == false
    end
  end
end
