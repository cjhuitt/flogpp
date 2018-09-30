require 'minitest/autorun'
require_relative "../lib/score"

class ScoreTest < Minitest::Test
  def test_defaults_to_zeros
    score = Score.new
    assert_equal 0, score.assignments
    assert_equal 0, score.branches
    assert_equal 0, score.conditionals
    assert_equal 0, score.overall
  end

  def test_addition
    x = Score.new 1, 2, 3
    y = Score.new 4, 5, 6
    sum = x + y
    assert_equal 5, sum.assignments
    assert_equal 7, sum.branches
    assert_equal 9, sum.conditionals
  end

  def test_addition_does_not_modify_original
    # Yes, I brainlessly messed this up once....
    x = Score.new 1, 2, 3
    y = Score.new 4, 5, 6
    sum = x + y
    assert_equal 1, x.assignments
    assert_equal 2, x.branches
    assert_equal 3, x.conditionals
    assert_equal 4, y.assignments
    assert_equal 5, y.branches
    assert_equal 6, y.conditionals
  end

  def test_addition_assignment
    x = Score.new 1, 2, 3
    y = Score.new 4, 5, 6
    x += y
    assert_equal 5, x.assignments
    assert_equal 7, x.branches
    assert_equal 9, x.conditionals
  end

  def test_overall_matches_only_additions
    score = Score.new a=2
    assert_equal 2, score.overall
  end

  def test_overall_matches_only_branches
    score = Score.new b=2
    assert_equal 2, score.overall
  end

  def test_overall_matches_only_conditionals
    score = Score.new c=2
    assert_equal 2, score.overall
  end

  def test_overall_is_vector_magnitude
    score = Score.new 1, 2, 3
    assert_in_delta 3.742, score.overall
  end

  def test_division
    score = Score.new 2, 4, 6
    avg = score / 2
    assert_equal 1, avg.assignments
    assert_equal 2, avg.branches
    assert_equal 3, avg.conditionals
  end

  def test_division_does_not_modify_original
    # Yes, I brainlessly messed this up once....
    score = Score.new 2, 4, 6
    avg = score / 2
    assert_equal 2, score.assignments
    assert_equal 4, score.branches
    assert_equal 6, score.conditionals
  end

  def test_division_assignment
    score = Score.new 2, 4, 6
    score /= 2
    assert_equal 1, score.assignments
    assert_equal 2, score.branches
    assert_equal 3, score.conditionals
  end
end
