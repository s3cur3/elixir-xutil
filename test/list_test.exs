defmodule XUtil.ListTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  doctest XUtil.List

  describe "rotate" do
    test "on an empty list produces an empty list" do
      assert XUtil.List.rotate([], 0..0, 0) == []
    end

    test "on a list of a single element produces the same list" do
      for single_element <- ["foo", 1, :foo, %{foo: "bar"}, MapSet.new(["foo"])] do
        assert XUtil.List.rotate([single_element], 0..0, 0) == [single_element]
      end
    end

    test "moves a single element" do
      expected_numbers = Enum.flat_map([0..7, [14], 8..13, 15..20], &Enum.to_list/1)
      assert XUtil.List.rotate(0..20, 14..14, 8) == expected_numbers

      assert XUtil.List.rotate([:a, :b, :c, :d, :e, :f], 3..3, 2) == [:a, :b, :d, :c, :e, :f]
    end

    test "on a subsection of a list reorders the range correctly" do
      expected_numbers = Enum.flat_map([0..7, 14..18, 8..13, 19..20], &Enum.to_list/1)
      assert XUtil.List.rotate(0..20, 14..18, 8) == expected_numbers

      assert XUtil.List.rotate([:a, :b, :c, :d, :e, :f], 3..4, 2) == [:a, :b, :d, :e, :c, :f]
    end

    test "handles reversed ranges" do
      expected_numbers = Enum.flat_map([0..7, 14..18, 8..13, 19..20], &Enum.to_list/1)
      assert XUtil.List.rotate(0..20, 18..14, 8) == expected_numbers

      assert XUtil.List.rotate([:a, :b, :c, :d, :e, :f], 4..3, 2) == [:a, :b, :d, :e, :c, :f]
    end

    property "handles reversed ranges" do
      check all(
              list <- StreamData.list_of(StreamData.integer(), max_length: 100),
              {range, insertion_point} <- rotation_spec(list)
            ) do
        reversed_range = %Range{first: range.last, last: range.first}

        assert XUtil.List.rotate(list, range, insertion_point) ==
                 XUtil.List.rotate(list, reversed_range, insertion_point)
      end
    end

    test "doesn't change the list when the first and middle indices match" do
      assert XUtil.List.rotate(0..20, 8..18, 8) == Enum.to_list(0..20)
      assert XUtil.List.rotate([:a, :b, :c, :d, :e, :f], 1..3, 1) == [:a, :b, :c, :d, :e, :f]
    end

    test "on the whole of a list reorders it correctly" do
      expected_numbers = Enum.flat_map([10..20, 0..9], &Enum.to_list/1)
      assert XUtil.List.rotate(0..20, 10..20, 0) == expected_numbers

      assert XUtil.List.rotate([:a, :b, :c, :d, :e, :f], 4..5, 0) == [:e, :f, :a, :b, :c, :d]
    end

    test "raises when the insertion point is inside the range" do
      assert_raise RuntimeError, fn ->
        XUtil.List.rotate(0..20, 10..18, 14)
      end
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
