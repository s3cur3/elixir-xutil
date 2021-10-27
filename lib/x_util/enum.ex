defmodule XUtil.Enum do
  @moduledoc """
  Algorithms I wish were included in Enum
  """

  @doc """
  Filters out ("rejects") the specified value.

      iex(1)> XUtil.Enum.drop([1, 2, 1, 3, 1, 4, 1, 5], 1)
      [2, 3, 4, 5]

      iex(1)> XUtil.Enum.drop([1, nil, 1, 3, nil, nil, 1, 5], nil)
      [1, 1, 3, 1, 5]
  """
  def drop(enumerable, val) do
    Enum.reject(enumerable, XUtil.Operator.equal(val))
  end

  @doc """
  Just the opposite of "any"

      iex(1)> XUtil.Enum.none?([1, 2, 3, 4, 5], fn val -> rem(val, 2) == 0 end)
      false
      iex(1)> XUtil.Enum.none?([1, 3, 5, 7, 9], fn val -> rem(val, 2) == 0 end)
      true
  """
  def none?(enumerable, predicate) do
    not Enum.any?(enumerable, predicate)
  end

  @doc """
  Pulls out either a single element (denoted by an integer index) or a contiguous range of
  the enumerable (given by a range) and inserts it in front of the value previously at the
  insertion index.

  The semantics of the range to be rotated match the semantics of Enum.slice/2. Specifically,
  that means:

  - Indices are normalized, meaning that negative indexes will be counted from the end
      (for example, -1 means the last element of the enumerable). This will result in *two*
      traversals of your enumerable on types like lists that don't provide a constant-time count.
  - If the normalized index range's `last` is out of bounds, the range is truncated to the last element.
  - If the normalized index range's `first` is out of bounds, the selected range for rotation
      will be empty, so you'll get back your input list.
  - Decreasing ranges (e.g., the range 5..0//1) also select an empty range to be rotated, so you'll
      get back your input list.
  - Ranges with any step but 1 will raise an error.

    # Rotate a single element
    iex> XUtil.Enum.rotate([0, 1, 2, 3, 4, 5, 6], 5, 1)
    [0, 5, 1, 2, 3, 4, 6]
    iex> XUtil.Enum.rotate(0..6, 2, 4)
    [0, 1, 3, 4, 2, 5, 6]

    # Rotate a range of elements backward
    iex> XUtil.Enum.rotate([0, 1, 2, 3, 4, 5, 6], 3..5, 1)
    [0, 3, 4, 5, 1, 2, 6]
    iex> XUtil.Enum.rotate(0..6, 1..7, 0)
    [1, 2, 3, 4, 5, 6, 0]

    # Rotate a range of elements forward
    iex> XUtil.Enum.rotate([0, 1, 2, 3, 4, 5, 6], 1..3, 5)
    [0, 4, 5, 1, 2, 3, 6]
    iex> XUtil.Enum.rotate([0, 1, 2, 3, 4, 5, 6], 2..4, 1)
    [0, 2, 3, 4, 1, 5, 6]

    # Rotate with negative indices (counting from the end)
    iex> XUtil.Enum.rotate([0, 1, 2, 3, 4, 5, 6], 3..-1//1, 2)
    [0, 1, 3, 4, 5, 6, 2]
    iex> XUtil.Enum.rotate([0, 1, 2, 3, 4, 5, 6], -4..-2, 1)
    [0, 3, 4, 5, 1, 2, 6]
  """
  def rotate(enumerable, range_or_single_index, insertion_index)

  def rotate(enumerable, single_index, insertion_index) when is_integer(single_index) do
    rotate(enumerable, single_index..single_index, insertion_index)
  end

  # This matches the behavior of Enum.slice/2
  def rotate(_, _.._//step = index_range, _insertion_index) when step != 1 do
    raise ArgumentError,
          "Enum.rotate/3 does not accept ranges with custom steps, got: #{inspect(index_range)}"
  end

  # Normalize negative input ranges like Enum.slice/2
  def rotate(enumerable, first..last, insertion_index) when first < 0 or last < 0 do
    count = Enum.count(enumerable)
    normalized_first = if first >= 0, do: first, else: first + count
    normalized_last = if last >= 0, do: last, else: last + count

    if normalized_first >= 0 and normalized_first < count and normalized_first != insertion_index do
      normalized_range = normalized_first..normalized_last//1
      rotate(enumerable, normalized_range, insertion_index)
    else
      Enum.to_list(enumerable)
    end
  end

  def rotate(enumerable, insertion_index.._, insertion_index) do
    Enum.to_list(enumerable)
  end

  def rotate(_, first..last, insertion_index)
      when insertion_index > first and insertion_index < last do
    raise "Insertion index for rotate must be outside the range being moved " <>
            "(tried to insert #{first}..#{last} at #{insertion_index})"
  end

  # Guarantees at this point: step size == 1 and first <= last and (insertion_index < first or insertion_index > last)
  def rotate(enumerable, first..last, insertion_index) do
    impl = if is_list(enumerable), do: &find_start/4, else: &rotate_any/4

    cond do
      insertion_index <= first -> impl.(enumerable, insertion_index, first, last)
      insertion_index > last -> impl.(enumerable, first, last + 1, insertion_index)
    end
  end

  # Takes the range from middle..last and moves it to be in front of index first
  defp rotate_any(enumerable, start, middle, last) do
    # We're going to deal with 4 "chunks" of the enumerable:
    # 0. "Head," before the start index
    # 1. "Rotate back," between start (inclusive) and middle (exclusive)
    # 2. "Rotate front," between middle (inclusive) and last (inclusive)
    # 3. "Tail," after last
    #
    # But, we're going to accumulate these into only two lists: pre and post.
    # We'll reverse-accumulate the head into our pre list, then "rotate back" into post,
    # then "rotate front" into pre, then "tail" into post.
    #
    # Then at the end, we're going to reassemble and reverse them, and end up with the
    # chunks in the correct order.
    {_size, pre, post} =
      Enum.reduce(enumerable, {0, [], []}, fn item, {index, pre, post} ->
        {pre, post} =
          cond do
            index < start -> {[item | pre], post}
            index >= start and index < middle -> {pre, [item | post]}
            index >= middle and index <= last -> {[item | pre], post}
            true -> {pre, [item | post]}
          end

        {index + 1, pre, post}
      end)

    :lists.reverse(pre, :lists.reverse(post))
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
