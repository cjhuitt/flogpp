require 'minitest/autorun'
require_relative "../lib/stats"
require_relative "../lib/score"

class RangeStub
  def initialize number=5
    @number = number
  end

  def count num
    return @number
  end
end

class StatsTest < Minitest::Test
  def test_multiple_if_more_than_one_in_collection
    score = Score.new
    collection = {'a' => score, 'b' => score}
    range = RangeStub.new
    stats = Stats.new collection, score, range
    assert stats.multiple?
  end

  def test_not_multiple_if_singular_collection
    score = Score.new
    collection = {'a' => score}
    range = RangeStub.new
    stats = Stats.new collection, score, range
    refute stats.multiple?
  end

  def test_not_multiple_if_empty_collection
    score = Score.new
    collection = {'a' => score}
    range = RangeStub.new
    stats = Stats.new collection, score, range
    refute stats.multiple?
  end

  def test_average
    score_a = Score.new 1, 0, 0
    score_b = Score.new 2, 0, 0
    collection = {'a' => score_a, 'b' => score_b}
    range = RangeStub.new
    stats = Stats.new collection, score_a + score_b, range
    assert_in_delta stats.average.overall, 1.5, 0.01
  end

  def test_worst_count_comes_from_range
    score = Score.new
    collection = {'a' => score, 'b' => score, 'c' => score, 'd' => score}
    range = RangeStub.new 3
    stats = Stats.new collection, score, range
    assert_equal 3, stats.worst.count
  end

  def test_score_sorting_default
    score_a = Score.new 1, 2, 1
    score_b = Score.new 2, 1, 2
    collection = {'a' => score_a, 'b' => score_b}
    range = RangeStub.new
    stats = Stats.new collection, score_a + score_b, range
    assert_equal 'b', stats.worst.first.first
  end

  def test_score_sorting_by_assignments
    score_a = Score.new 1, 2, 1
    score_b = Score.new 2, 1, 2
    collection = {'a' => score_a, 'b' => score_b}
    range = RangeStub.new
    stats = Stats.new collection, score_a + score_b, range, sort = :assignments
    assert_equal 'b', stats.worst.first.first
  end

  def test_score_sorting_by_branches
    score_a = Score.new 1, 2, 1
    score_b = Score.new 2, 1, 2
    collection = {'a' => score_a, 'b' => score_b}
    range = RangeStub.new
    stats = Stats.new collection, score_a + score_b, range, sort = :branches
    assert_equal 'a', stats.worst.first.first
  end

  def test_score_sorting_by_conditionals
    score_a = Score.new 1, 2, 1
    score_b = Score.new 2, 1, 2
    collection = {'a' => score_a, 'b' => score_b}
    range = RangeStub.new
    stats = Stats.new collection, score_a + score_b, range, sort = :conditionals
    assert_equal 'b', stats.worst.first.first
  end
end
