# attempt to calculate damerau-levenshtein equivalence of 2 strings with distance k

defmodule DamerauLevenshtein do
  @moduledoc """
  Compute whether the damerau-levenshtein distance between 2 strings is at or below k (cost).
  This entails tallying the total cost of all insertions, deletions, substitutions and transpositions
  """

  @doc """
  Test for Damerau-Levenshtein equivalency, given two strings and a k (cost/distance) value.
  """
  def equivalent?(candidate, target, k) do
    distance(candidate, target, k) <= k
  end

  # handle simplest cases breezily

  @doc """
  no max cost provided
  """
  def distance(a, b) do
    distance(a, b, 10)
  end

  @doc """
  initialize current_cost state
  """
  def distance(a, b, max) do
    distance(a, b, max, 0)
  end

  @doc """
  current_cost exceeds max_cost
  """
  def distance(_, _, max_cost, current_cost) when current_cost > max_cost do
    # can't error or raise here since other recursions may find smaller costs, so just return max+1
    # also because the distance function is expected to return an integer.
    max_cost + 1
  end

  @doc """
  empty strings
  """
  def distance("", "", _max_cost, current_cost) do
    # IO.puts "Remaining strings empty"
    current_cost
  end

  def distance("", b, _max_cost, current_cost) do
    current_cost + String.length(b)
  end

  def distance(a, "", _max_cost, current_cost) do
    current_cost + String.length(a)
  end

  @doc """
  two equivalent strings
  """
  def distance(same, same, _max_cost, current_cost) do
    # IO.puts "Remaining strings the same: #{same}"
    current_cost
  end

  @doc """
  if both heads are the same, advance both
  """
  def distance(<<equal_char::utf8, candidate_tail::binary>>, <<equal_char::utf8, target_tail::binary>>, max_cost, current_cost) do
    # IO.puts "Both chars same: '#{equal_char}' Advancing both"
    distance(candidate_tail, target_tail, max_cost, current_cost)
  end

  @doc """
  heads are different, but a transposition is in place. advance both and increment cost by 1
  """
  def distance(<<first_char::utf8, second_char::utf8, candidate_tail::binary>>, <<second_char::utf8, first_char::utf8, target_tail::binary>>, max_cost, current_cost) do
    # IO.puts "Transposition seen between #{first_char}#{second_char} and #{second_char}#{first_char}."
    distance(candidate_tail, target_tail, max_cost, current_cost + 1)
  end

  @doc """
  heads are different, assume a substitution OR 1 deletion in either side (an insertion relative to the other side) and return minimum value of all costs.
  Note that this is where runtimes can get hairy in worst cases, there's no TCO here
  """
  def distance(whole_candidate = <<_candidate_head::utf8, candidate_tail::binary>>, whole_target = <<_target_head::utf8, target_tail::binary>>, max_cost, current_cost) do
    Enum.min([
      distance(candidate_tail, target_tail, max_cost, current_cost + 1),  # substitution of character
      distance(candidate_tail, whole_target, max_cost, current_cost + 1), # single deletion in candidate (insertion in target)
      distance(whole_candidate, target_tail, max_cost, current_cost + 1)  # single deletion in target (insertion in candidate)
    ])
  end

end

# run this inline suite with "elixir #{__ENV__.file} test"
if System.argv |> List.first == "test" do
  ExUnit.start

  defmodule DamerauLevenshteinTest do
    use ExUnit.Case, async: true
    alias DamerauLevenshtein, as: DL

    test "distance of empty strings" do
      assert 0 == DL.distance("","")
    end

    test "distance of equivalent strings" do
      assert 0 == DL.distance("test", "test")
    end

    test "distance of strings with empty string" do
      assert 4 == DL.distance("", "test")
      assert 4 == DL.distance("test", "")
    end

    test "transpositions" do
      assert 1 == DL.distance("etst", "test")
      assert 1 == DL.distance("tset", "test")
      assert 1 == DL.distance("tets", "test")
      assert 2 == DL.distance("etts", "test")
      assert 2 == DL.distance("eptre", "peter")
    end

    test "substitutions" do
      assert 1 == DL.distance("test", "tent")
      assert 2 == DL.distance("terp", "test")
    end

    test "insertions/deletions of 1 character" do
      assert 1 == DL.distance("Peter", "Petter")
      assert 1 == DL.distance("Petter", "Peter")
    end

    test "combination of an insertion and a transposition" do
      assert 2 == DL.distance("Peter", "Peetre")
    end

    test "an insertion, a deletion, a substitution and a transposition" do
      assert 4 == DL.distance("Peter", "pterre")
    end

    test "an extra/missing word" do
      assert 6 == DL.distance("four score and", "four and")
      assert 6 == DL.distance("four and", "four score and")
    end

    test "distance against empty string" do
      assert 7 == DL.distance("testing", "", 4)
    end

    test "distance exceeds max" do
      assert 5 == DL.distance("testing", "a", 4)
    end

    test "arbitrary differences taken from other test suites" do
      assert 4 == DL.distance("Toralf", "Titan")
      assert 8 == DL.distance("rosettacode", "raisethysword")
      assert 3 == DL.distance("Saturday", "Sunday") # 2 deletions, 1 substitution
      assert 3 == DL.distance("kitten", "sitting") # 2 substitutions, 1 insertion
      # dna, anyone?
      # I just realized that the movie title "Gattaca" only uses DNA letters. ::slaps forehead::
      assert 4 == DL.distance("ACGTTGACCATGAGTCCAG", "ACGTGTACCCTGGTACCAG")
    end

    # Optimal string alignment distance special cases:
    # see http://en.wikipedia.org/wiki/Damerau%E2%80%93Levenshtein_distance
    # Damerau-Levenshtein("CA", "ABC") is CA -> AC -> ABC == 2 steps, 1 transpose and 1 insert
    test "optimal string distance" do
      # this one is tough! is it necessary? Commented out for now
      assert 2 == DL.distance("CA", "ABC")
    end

    test "d-l equivalence" do
      assert DL.equivalent?("Peter", "Petter", 1)
      refute DL.equivalent?("Peter", "Pesterer", 2)
    end
  end
end
