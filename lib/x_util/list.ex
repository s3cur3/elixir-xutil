defmodule XUtil.List do
  @moduledoc """
  Algorithms I wish were included in List
  """

  @doc """
  Given three indices (start, middle, and last, inclusive), this pulls out the elements
  in the range [`middle`, `last`] and inserts them at index `start`. This reorders the range
  [`first`, `last`] such that the item at index `middle` becomes first, and the item at index
  `middle` - 1 becomes the last.

    iex(1)> XUtil.List.rotate([0, 1, 2, 3, 4, 5, 6], 1, 3, 5)
    [0, 3, 4, 5, 1, 2, 6]
    iex(1)> XUtil.List.rotate([0, 1, 2, 3, 4, 5, 6], 0, 1, 7)
    [1, 2, 3, 4, 5, 6, 0]
  """
  def rotate(enumerable, start, middle, last) do
    {unchanged_start, after_insertion_pt} = Enum.split(enumerable, start)
    # to_rotate contains just the elements in the range [start, last]
    {to_rotate, unchanged_end} = Enum.split(after_insertion_pt, last - start + 1)
    {new_end_of_rotated_range, new_start_of_rotated_range} = Enum.split(to_rotate, middle - start)

    unchanged_start ++ new_start_of_rotated_range ++ new_end_of_rotated_range ++ unchanged_end
  end

  @doc """
  Pulls out the elements in the range [`range_start_idx`, `range_end_idx`] and inserts them at
  `insertion_idx`, returning the reassembled enumerable as a list.
  """
  def slide(enumerable, range_start_idx, range_end_idx, insertion_idx)

  def slide(enumerable, range_start_idx, range_end_idx, insertion_idx)
      when insertion_idx < range_start_idx do
    rotate(enumerable, insertion_idx, range_start_idx, range_end_idx)
  end

  def slide(enumerable, range_start_idx, range_end_idx, insertion_idx)
      when insertion_idx > range_start_idx do
    rotate(enumerable, range_start_idx, range_end_idx, insertion_idx)
  end

  def slide(enumerable, _, _, _), do: Enum.to_list(enumerable)
end
