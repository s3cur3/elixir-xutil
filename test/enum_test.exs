defmodule XUtil.EnumTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  doctest XUtil.Enum

  describe "rotate" do
    property "matches behavior for lists vs. ranges" do
      # Below 32 elements, the map implementation currently sticks the pairs these in order
      range = 0..20
      list = Enum.to_list(range)
      set = MapSet.new(list)

      check all({range, insertion_point} <- rotation_spec(list)) do
        rotation = &XUtil.Enum.rotate(&1, range, insertion_point)
        assert rotation.(list) == rotation.(set)
      end

      zipped_list = Enum.zip(list, list)
      map = Map.new(zipped_list)

      check all({range, insertion_point} <- rotation_spec(zipped_list)) do
        rotation = &XUtil.Enum.rotate(&1, range, insertion_point)
        assert rotation.(zipped_list) == rotation.(map)
      end
    end

    test "on an empty enum produces an empty list" do
      for enum <- [[], %{}, 0..-1//1, MapSet.new()] do
        assert XUtil.Enum.rotate(enum, 0..0, 0) == []
      end
    end

    test "on a list of a single element produces the same list" do
      for single_element <- ["foo", 1, :foo, %{foo: "bar"}, MapSet.new(["foo"])] do
        assert XUtil.Enum.rotate([single_element], 0..0, 0) == [single_element]
      end
    end

    test "moves a single element" do
      expected_numbers = Enum.flat_map([0..7, [14], 8..13, 15..20], &Enum.to_list/1)
      assert XUtil.Enum.rotate(0..20, 14..14, 8) == expected_numbers

      assert XUtil.Enum.rotate([:a, :b, :c, :d, :e, :f], 3..3, 2) == [:a, :b, :d, :c, :e, :f]
    end

    test "on a subsection of a list reorders the range correctly" do
      expected_numbers = Enum.flat_map([0..7, 14..18, 8..13, 19..20], &Enum.to_list/1)
      assert XUtil.Enum.rotate(0..20, 14..18, 8) == expected_numbers

      assert XUtil.Enum.rotate([:a, :b, :c, :d, :e, :f], 3..4, 2) == [:a, :b, :d, :e, :c, :f]
    end

    property "handles negative indices" do
      check all(
              list <- StreamData.list_of(StreamData.integer(), max_length: 100),
              {range, insertion_point} <- rotation_spec(list)
            ) do
        length = length(list)
        negative_range = %Range{first: range.first - length, last: range.last - length, step: 1}

        assert XUtil.Enum.rotate(list, negative_range, insertion_point) ==
                 XUtil.Enum.rotate(list, range, insertion_point)
      end
    end

    test "handles mixed positive and negative indices" do
      assert XUtil.Enum.rotate(0..20, -6..-1, 8) == XUtil.Enum.rotate(0..20, 15..20, 8)
      assert XUtil.Enum.rotate(0..20, 15..-1//1, 8) == XUtil.Enum.rotate(0..20, 15..20, 8)
      assert XUtil.Enum.rotate(0..20, -6..20, 8) == XUtil.Enum.rotate(0..20, 15..20, 8)
    end

    test "raises an error when the step is not exactly 1" do
      rotation_ranges_that_should_fail = [2..10//2, 8..-1, 10..2//-1, 10..4//-2, -1..-8//-1]

      Enum.each(rotation_ranges_that_should_fail, fn range_that_should_fail ->
        assert_raise(ArgumentError, fn ->
          XUtil.Enum.rotate(0..20, range_that_should_fail, 1)
        end)
      end)
    end

    test "doesn't change the list when the first and middle indices match" do
      assert XUtil.Enum.rotate(0..20, 8..18, 8) == Enum.to_list(0..20)
      assert XUtil.Enum.rotate([:a, :b, :c, :d, :e, :f], 1..3, 1) == [:a, :b, :c, :d, :e, :f]
    end

    test "on the whole of a list reorders it correctly" do
      expected_numbers = Enum.flat_map([10..20, 0..9], &Enum.to_list/1)
      assert XUtil.Enum.rotate(0..20, 10..20, 0) == expected_numbers

      assert XUtil.Enum.rotate([:a, :b, :c, :d, :e, :f], 4..5, 0) == [:e, :f, :a, :b, :c, :d]
    end

    test "raises when the insertion point is inside the range" do
      assert_raise RuntimeError, fn ->
        XUtil.Enum.rotate(0..20, 10..18, 14)
      end
    end

    test "accepts range starts that are off the end of the list, returning the input list" do
      assert XUtil.Enum.rotate([], 1..5, 0) == []
      assert XUtil.Enum.rotate(0..20, 21..25, 3) == Enum.to_list(0..20)
    end

    test "accepts range ends that are off the end of the list, truncating the rotated range" do
      assert XUtil.Enum.rotate(0..10, 8..15, 4) == XUtil.Enum.rotate(0..10, 8..10, 4)
    end
  end

  # Generator for valid rotations on the input list
  # Generates values of the form:
  #   {range_to_rotate, insertion_point}
  # ...such that the two arguments are always valid on the given list.
  defp rotation_spec(list) do
    max_idx = max(0, length(list) - 1)

    StreamData.bind(StreamData.integer(0..max_idx), fn first ->
      StreamData.bind(StreamData.integer(first..max_idx), fn last ->
        allowable_insertion_points_at_end =
          if last < max_idx do
            [StreamData.integer((last + 1)..max_idx)]
          else
            []
          end

        allowable_insertion_points = [StreamData.integer(0..first)] ++ allowable_insertion_points_at_end

        StreamData.bind(one_of(allowable_insertion_points), fn insertion_point ->
          StreamData.constant({first..last, insertion_point})
        end)
      end)
    end)
  end
end
