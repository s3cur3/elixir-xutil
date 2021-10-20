defmodule XUtil.List do
  @moduledoc """
  Algorithms I wish were included in List
  """

  @doc """
  Pulls out either a single element (denoted by an integer index) or a contiguous range of
  the list (given by a range) and inserts it in front of the value previously at the insertion
  index.

  The semantics of the the range to be rotated match the semantics of Enum.slice/2. Specifically,
  that means:

  - Indexes are normalized, meaning that negative indexes will be counted from the end
      (for example, -1 means the last element of the enumerable).
  - If the normalized index range's `last` is out of bounds, the range is truncated to the last element.
  - If the normalized index_range's `first` is out of bounds, the selected range for rotation
      will be empty, so you'll get back your input list.
  - Decreasing ranges (e.g., the range 5..0) also select an empty range to be rotated, so you'll
      get back your input list.
  - Ranges with a custom step (anything but 1 or -1) will raise an error.

    # Rotate a single element
    iex> XUtil.List.rotate([0, 1, 2, 3, 4, 5, 6], 5, 1)
    [0, 5, 1, 2, 3, 4, 6]
    iex> XUtil.List.rotate([0, 1, 2, 3, 4, 5, 6], 2, 4)
    [0, 1, 3, 4, 2, 5, 6]

    # Rotate a range of elements backward
    iex> XUtil.List.rotate([0, 1, 2, 3, 4, 5, 6], 3..5, 1)
    [0, 3, 4, 5, 1, 2, 6]
    iex> XUtil.List.rotate([0, 1, 2, 3, 4, 5, 6], 1..7, 0)
    [1, 2, 3, 4, 5, 6, 0]

    # Rotate a range of elements forward
    iex> XUtil.List.rotate([0, 1, 2, 3, 4, 5, 6], 1..3, 5)
    [0, 4, 5, 1, 2, 3, 6]
    iex> XUtil.List.rotate([0, 1, 2, 3, 4, 5, 6], 2..4, 1)
    [0, 2, 3, 4, 1, 5, 6]
  """
  def rotate(list, range_or_single_index, insertion_index)

  def rotate(%Range{} = enumerable, range_or_single_index, insertion_index) do
    rotate(Enum.to_list(enumerable), range_or_single_index, insertion_index)
  end

  def rotate(enumerable, single_index, insertion_index) when is_integer(single_index) do
    rotate(enumerable, single_index..single_index, insertion_index)
  end

  # Normalize negative input ranges like Enum.slice/2
  def rotate(enumerable, first..last//step, insertion_index)
      when (first < 0 or last < 0) and (step == 1 or step == -1) do
    count = length(enumerable)
    normalized_first = if first >= 0, do: first, else: first + count
    normalized_last = if last >= 0, do: last, else: last + count
    normalized_step = if normalized_first <= normalized_last, do: 1, else: -1

    if normalized_first >= 0 and normalized_first < count do
      normalized_range = normalized_first..normalized_last//normalized_step
      rotate(enumerable, normalized_range, insertion_index)
    else
      Enum.to_list(enumerable)
    end
  end

  def rotate(enumerable, first..last//1, insertion_index)
      when first <= last and (insertion_index < first or insertion_index > last) do
    cond do
      insertion_index <= first -> find_start(enumerable, insertion_index, first, last)
      insertion_index > last -> find_start(enumerable, first, last + 1, insertion_index)
      true -> raise "Insertion index for rotate must be outside the range being moved"
    end
  end

  def rotate(enumerable, %Range{first: insertion_index}, insertion_index) do
    Enum.to_list(enumerable)
  end

  # This matches the behavior of Enum.slice/2 when given "reversed" ranges, which is to consider
  # the slice entirely empty.
  def rotate(enumerable, %Range{step: step}, _insertion_index) when step == -1 do
    Enum.to_list(enumerable)
  end

  # This matches the behavior of Enum.slice/2
  def rotate(_enumerable, %Range{step: step} = index_range, _insertion_index) when step > 1 do
    raise ArgumentError,
          "List.rotate/3 does not accept ranges with custom steps, got: #{inspect(index_range)}"
  end

  def rotate(_, %Range{first: first, last: last}, insertion_index) do
    raise "Insertion index for rotate must be outside the range being moved " <>
            "(tried to insert #{first}..#{last} at #{insertion_index})"
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
