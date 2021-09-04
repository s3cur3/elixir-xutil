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
  # TODO: Support negative indices/ranges
  # TODO: Make it clear the semantics of the range are based on the semantics of Enum.slice/2
  #       and the semantics of "end" on insert_at
  # TODO: Support ranges with a :step (1.12+)
  def rotate(enumerable, %Range{first: first, last: last}, insertion_index)
      when first != insertion_index do
    if insertion_index < first do
      rotate_contiguous(enumerable, insertion_index, first, last)
    else
      rotate_contiguous(enumerable, first, last + 1, insertion_index)
    end
  end

  def rotate(enumerable, _range, _insertion_index) do
    Enum.to_list(enumerable)
  end

  # This has the semantics of C++'s std::rotate
  # Given three indices (start, middle, and last, inclusive), this pulls out the elements
  # in the range [`middle`, `last`] and inserts them at index `start`. This reorders the range
  # [`first`, `last`] such that the item at index `middle` becomes first, and the item at index
  # `middle` - 1 becomes the last.
  defp rotate_contiguous(enumerable, start, middle, last) do
    {unchanged_start, after_insertion_pt} = Enum.split(enumerable, start)
    # to_rotate contains just the elements in the range [start, last]
    {to_rotate, unchanged_end} = Enum.split(after_insertion_pt, last - start + 1)
    {new_end_of_rotated_range, new_start_of_rotated_range} = Enum.split(to_rotate, middle - start)

    unchanged_start ++ new_start_of_rotated_range ++ new_end_of_rotated_range ++ unchanged_end
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
end
