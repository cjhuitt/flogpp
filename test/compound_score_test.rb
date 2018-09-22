require 'minitest/autorun'
require_relative '../lib/compound_analyzer'

class CompoundAnalyzerScoreTest < Minitest::Test
  def test_scores_zero_for_empty_function
    code = "void foo() { }"
    compound_analyzer = CompoundAnalyzer.new code
    assert_equal 0, compound_analyzer.score
  end

  def test_scores_one_for_simple_assignment
    code = "a = 0;"
    compound_analyzer = CompoundAnalyzer.new code
    assert_equal 1, compound_analyzer.score
  end

  def test_scores_two_for_assignment_from_function
    code = "a = b->foo();"
    compound_analyzer = CompoundAnalyzer.new code
    assert_equal 2, compound_analyzer.score
  end

  def test_scores_two_for_multiple_assigments_on_one_line
    code = "    int a=2,b=3;"
    compound_analyzer = CompoundAnalyzer.new code
    assert_equal 2, compound_analyzer.score
  end

  def test_scores_two_for_assignments_on_two_lines
    code = "    int a=2;\nb=3;"
    compound_analyzer = CompoundAnalyzer.new code
    assert_equal 2, compound_analyzer.score
  end

  def test_score_recursive_fibonacci
    code = <<-CODE
    if (x == 1) {
        return 1;
    } else if (x == 0) {
        return 0;
    } else {
        return fib(x-1)+fib(x-2);
    }
    CODE
    compound_analyzer = CompoundAnalyzer.new code
    assert_equal 6, compound_analyzer.score
  end
end

