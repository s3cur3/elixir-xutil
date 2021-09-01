defmodule XUtil.ListTest do
  use ExUnit.Case, async: true
  doctest XUtil.List

  describe "rotate" do
    test "on an empty list produces an empty list" do
      assert XUtil.List.rotate([], 0, 0, 0) == []
    end

    test "on a list of a single element produces the same list" do
      assert XUtil.List.rotate(["foo"], 0, 0, 0) == ["foo"]
      assert XUtil.List.rotate([1], 0, 0, 0) == [1]
      assert XUtil.List.rotate([:foo], 0, 0, 0) == [:foo]
      assert XUtil.List.rotate([%{foo: "bar"}], 0, 0, 0) == [%{foo: "bar"}]
    end

    test "moves a single element" do
      expected_numbers = Enum.flat_map([0..7, [14], 8..13, 15..20], &Enum.to_list/1)
      assert XUtil.List.rotate(0..20, 8, 14, 14) == expected_numbers

      assert XUtil.List.rotate([:a, :b, :c, :d, :e, :f], 2, 3, 3) == [:a, :b, :d, :c, :e, :f]
    end

    test "on a subsection of a list reorders the range correctly" do
      expected_numbers = Enum.flat_map([0..7, 14..18, 8..13, 19..20], &Enum.to_list/1)
      assert XUtil.List.rotate(0..20, 8, 14, 18) == expected_numbers

      assert XUtil.List.rotate([:a, :b, :c, :d, :e, :f], 2, 3, 4) == [:a, :b, :d, :e, :c, :f]
    end

    test "doesn't change the list when the first and middle indices match" do
      assert XUtil.List.rotate(0..20, 8, 8, 18) == Enum.to_list(0..20)
      assert XUtil.List.rotate([:a, :b, :c, :d, :e, :f], 1, 1, 3) == [:a, :b, :c, :d, :e, :f]
    end

    test "on the whole of a list reorders it correctly" do
      expected_numbers = Enum.flat_map([10..20, 0..9], &Enum.to_list/1)
      assert XUtil.List.rotate(0..20, 0, 10, 20) == expected_numbers

      assert XUtil.List.rotate([:a, :b, :c, :d, :e, :f], 0, 4, 5) == [:e, :f, :a, :b, :c, :d]
    end
  end
end
