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
    if (x == 1) {                  // 1 conditional for ==
        return 1;
    } else if (x == 0) {           // 1 conditional for ==
        return 0;
    } else {                       // 1 conditional for else
        return fib(x-1)+fib(x-2);  // 2 branches for function calls
    }
    CODE
    compound_analyzer = CompoundAnalyzer.new code
    assert_equal 5, compound_analyzer.score
  end

  def test_score_iterative_fibonacci
    code = <<-CODE
    unsigned long fib(unsigned int n) {
        if (n == 0) return 0;
        unsigned long previous = 0;
        unsigned long current = 1;
        for (unsigned int i = 1; i < n; ++i) {
            unsigned long next = previous + current;
            previous = current;
            current = next;
        }
        return current;
    }
    CODE
      #cleaner = SnippetAnalyzer::Cleaner.new code
      #cleaned = cleaner.cleaned_code
      #cleaned = cleaner.clean_function_declarations_from cleaner.cleaned_code
      #puts cleaned.scan(/\b\w+\s*(<<=|>>=)\s*\w+\b/).size
      #puts cleaned.scan(/[^!=><]\s*=\s*[^!=]/).size
      #puts cleaned.scan("++").size
      #puts cleaned.scan("--").size
    compound_analyzer = CompoundAnalyzer.new code
      #snippet = SnippetAnalyzer.new code
      #assert_equal 6, snippet.assignments
    assert_equal 9, compound_analyzer.score
  end
end

