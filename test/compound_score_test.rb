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
end

