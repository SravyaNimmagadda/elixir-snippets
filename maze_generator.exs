defmodule Maze do
  def generate(w, h, maze \\ %{}, rand_seed \\ :os.timestamp) do
    :random.seed(rand_seed)
    :rand.seed(:exs64, rand_seed)
    maze_tuples = (for i <- 1..w, j <- 1..h, do: {i,j})
    maze = Enum.reduce(maze_tuples, maze, fn({i,j}, maze) -> Map.put(maze, {:vis, i, j}, true) end)
    get(w, h, walk(:random.uniform(w), :random.uniform(h), maze))
  end

  def print(w, h, maze \\ %{}, rand_seed \\ :os.timestamp) do
    Maze.generate(w, h, maze, rand_seed) |> Enum.each(&IO.puts(&1))
  end

  defp walk(x, y, %{} = maze) do
    Enum.reduce(
      Enum.shuffle([{x-1,y}, {x,y+1}, {x+1,y}, {x,y-1}]),
      %{maze | {:vis, x, y} => false},
      fn({i,j}, maze) ->
        if maze[{:vis, i, j}] do
          walk(i, j, (if i == x, do: Map.put(maze, {:hor, x, max(y, j)}, "+   "), else: Map.put(maze, {:ver, max(x, i), y}, "    ")))
        else
          maze
        end
      end
    )
  end

  defp get(w, h, %{} = maze) do
    Enum.map(1..h, fn j ->
      [(Enum.map(1..w, fn i -> Map.get(maze, {:hor, i, j}, "+---") end) |> Enum.join) <> "+",
       (Enum.map(1..w, fn i -> Map.get(maze, {:ver, i, j}, "|   ") end) |> Enum.join) <> "|"]
    end) ++ [String.duplicate("+---", w) <> "+"]
    |> List.flatten
  end
end

# run this inline suite with "elixir #{__ENV__.file} test"
if System.argv |> List.first == "test" do
  ExUnit.start

  defmodule MazeTest do
    use ExUnit.Case, async: true
    @rand_seed {1454, 367294, 550155}

    test "5x5 output as expected" do
      assert Maze.generate(5, 5, %{}, @rand_seed) == [
        "+---+---+---+---+---+",
        "|                   |",
        "+   +---+---+---+   +",
        "|       |           |",
        "+   +---+   +---+---+",
        "|   |       |       |",
        "+   +---+---+---+   +",
        "|   |               |",
        "+   +   +---+---+   +",
        "|       |           |",
        "+---+---+---+---+---+"
      ]
    end
  end
end

# run this inline performance suite with "elixir #{__ENV__.file} perf"
if System.argv |> List.first == "perf" do
  # just a timing utility
  defmodule Time do
    def now, do: ({msecs, secs, musecs} = :erlang.timestamp; ((msecs*1000000 + secs)*1000000 + musecs)/1000000)
  end
  iters = 5000
  i = 20
  j = 20
  t = Time.now
  Enum.each(1..iters, fn(_) -> Maze.generate(i,j) end)
  IO.puts "elapsed time #{Time.now - t} secs for #{iters} iterations of a #{i}x#{j} maze"
end
