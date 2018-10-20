require 'minitest/autorun'
require_relative "../lib/range"

class RangeTest < Minitest::Test
  def test_count_zero_with_zero_size
    range = Range.new
    assert_equal 0, range.count(0)
  end

  def test_count_ten_percent_by_default
    range = Range.new
    assert_equal 1, range.count(10)
  end

  def test_count_rounds_by_default
    range = Range.new
    assert_equal 1, range.count(14)
    assert_equal 2, range.count(15)
  end

  def test_count_at_least_one_if_non_zero_size
    range = Range.new
    assert_equal 1, range.count(1)
  end

  def test_count_all_if_full_specified
    range = Range.new full: true
    assert_equal 10, range.count(10)
  end

  def test_count_by_specified_percent
    range = Range.new percent: 50
    assert_equal 5, range.count(10)
  end

  def test_count_full_if_full_and_percent_specified
    range = Range.new percent: 50, full: true
    assert_equal 10, range.count(10)
  end

  def test_count_by_max_number
    range = Range.new number: 7
    assert_equal 7, range.count(10)
  end

  def test_count_by_max_number_not_more_than_count
    range = Range.new number: 17
    assert_equal 10, range.count(10)
  end

  def test_count_full_if_full_and_max_number_specified
    range = Range.new number: 5, full: true
    assert_equal 10, range.count(10)
  end

  def test_count_number_if_number_more_than_max_percent
    range = Range.new percent: 50, number: 7
    assert_equal 7, range.count(10)
  end

  def test_count_number_if_max_percent_zero
    range = Range.new percent: 0, number: 7
    assert_equal 7, range.count(10)
  end

  def test_count_number_if_less_than_default_percent
    range = Range.new number: 1
    assert_equal 1, range.count(20)
  end

  def test_count_percent_if_number_less_than_max_percent
    range = Range.new percent: 50, number: 3
    assert_equal 5, range.count(10)
  end

  def test_count_full_if_all_specified
    range = Range.new number: 3, percent: 50, full: true
    assert_equal 10, range.count(10)
  end
end
