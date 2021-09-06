defmodule XUtil.List do
  @moduledoc """
  Algorithms I wish were included in List
  """

  @doc """
  Given a range of list indices, pulls out the elements in that range and inserts them
  in front of the previous value at the insertion index.

    iex> XUtil.List.rotate([0, 1, 2, 3, 4, 5, 6], 3..5, 1)
    [0, 3, 4, 5, 1, 2, 6]
    iex> XUtil.List.rotate([0, 1, 2, 3, 4, 5, 6], 1..7, 0)
    [1, 2, 3, 4, 5, 6, 0]

    iex> XUtil.List.rotate([0, 1, 2, 3, 4, 5, 6], 1..3, 5)
    [0, 4, 5, 1, 2, 3, 6]
    iex> XUtil.List.rotate([0, 1, 2, 3, 4, 5, 6], 2..4, 1)
    [0, 2, 3, 4, 1, 5, 6]
  """
  def rotate(%Range{} = enumerable, range, insertion_index) do
    rotate(Enum.to_list(enumerable), range, insertion_index)
  end

  # TODO: Support negative indices/ranges
  # TODO: Make it clear the semantics of the range are based on the semantics of Enum.slice/2
  #       and the semantics of "end" on insert_at
  # TODO: Support ranges with a :step (1.12+)? Enum.slice/2 raises an error, so maybe not
  def rotate(enumerable, first..last, insertion_index)
      when insertion_index < first or insertion_index > last do
    cond do
      insertion_index <= first -> find_start(enumerable, insertion_index, first, last)
      insertion_index > last -> find_start(enumerable, first, last + 1, insertion_index)
      true -> raise "Insertion index for rotate must be outside the range being moved"
    end
  end

  def rotate(enumerable, %Range{first: insertion_index}, insertion_index) do
    Enum.to_list(enumerable)
  end

  def rotate(_, %Range{first: first, last: last}, insertion_index) do
    raise "Insertion index for rotate must be outside the range being moved " <>
          "(tried to insert #{first}..#{last} at #{insertion_index})"
  end

  @doc """
  Moves a single element from its current index to a target index.

    iex> XUtil.List.rotate_one([0, 1, 2, 3, 4, 5, 6], 5, 1)
    [0, 5, 1, 2, 3, 4, 6]
    iex> XUtil.List.rotate_one([0, 1, 2, 3, 4, 5, 6], 2, 4)
    [0, 1, 3, 4, 2, 5, 6]
  """
  def rotate_one(enumerable, idx_to_move, insertion_idx) do
    rotate(enumerable, idx_to_move..idx_to_move, insertion_idx)
  end

  # If end is after middle, we can use a non-tail recursive to start traverse until we find the start:
  # This guarantees the list is only copied once (plus one additional copy for the start..middle slice).
  # A similar approach can be devised if the end is before the start.
  defp find_start([h | t], start, middle, last)
       when start > 0 and start <= middle and middle <= last do
    [h | find_start(t, start - 1, middle - 1, last - 1)]
  end

  defp find_start(list, 0, middle, last), do: accumulate_start_middle(list, middle, last, [])

  defp accumulate_start_middle([h | t], middle, last, acc) when middle > 0 do
    accumulate_start_middle(t, middle - 1, last - 1, [h | acc])
  end

  defp accumulate_start_middle(list, 0, last, start_to_middle) do
    {rotated_range, tail} = accumulate_middle_last(list, last + 1, [])
    rotated_range ++ :lists.reverse(start_to_middle, tail)
  end

  # You asked for a middle index off the end of the list... you get what we've got
  defp accumulate_start_middle([], _, _, acc) do
    :lists.reverse(acc)
  end

  defp accumulate_middle_last([h | t], last, acc) when last > 0 do
    accumulate_middle_last(t, last - 1, [h | acc])
  end

  defp accumulate_middle_last(rest, 0, acc) do
    {:lists.reverse(acc), rest}
  end

  defp accumulate_middle_last([], _, acc) do
    {:lists.reverse(acc), []}
  end
end
