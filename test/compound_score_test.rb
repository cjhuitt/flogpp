require 'minitest/autorun'
require_relative '../lib/compound_analyzer'

class CompoundAnalyzerScoreTest < Minitest::Test
  def test_scores_zero_for_empty_function
    code = "void foo() { }"
    compound_analyzer = CompoundAnalyzer.new( code )
    assert_equal 0, compound_analyzer.score
  end

  def test_scores_one_for_simple_assignment
    code = "a = 0;"
    compound_analyzer = CompoundAnalyzer.new( code )
    assert_equal 1, compound_analyzer.score
  end

  def test_scores_two_for_assignment_from_function
    code = "a = b->foo();"
    compound_analyzer = CompoundAnalyzer.new( code )
    assert_equal 2, compound_analyzer.score
  end

  def test_scores_two_for_multiple_assigments_on_one_line
    code = "    int a=2,b=3;"
    compound_analyzer = CompoundAnalyzer.new( code )
    assert_equal 2, compound_analyzer.score
  end
end

