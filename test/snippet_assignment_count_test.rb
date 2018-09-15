require 'minitest/autorun'
require_relative '../lib/snippet_analyzer'

class SimpleSnippetAssignmentCountTest < Minitest::Test
  def test_finds_zero_assignments_for_empty_function
    code = "void foo() { }"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 0, function_analyzer.assignments
  end

  def test_finds_zero_assignments_for_return_keyword
    code = "return 37;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 0, function_analyzer.assignments
  end

  def test_finds_zero_assignments_for_default_parameters
    code = "void foo( int a = 0, float b = 0.05f ) { }"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 0, function_analyzer.assignments
  end

  def test_finds_zero_assignments_for_c_comment
    code = "/* a = foo(); */"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 0, function_analyzer.assignments
  end

  def test_finds_zero_assignments_for_cpp_comment
    code = "// a = foo();"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 0, function_analyzer.assignments
  end

  def test_finds_one_assignment_for_simple_assignment
    code = "a = 1;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, function_analyzer.assignments
  end

  def test_finds_one_assignment_for_assignment_from_variable
    code = "a = b;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, function_analyzer.assignments
  end

  def test_finds_one_assignment_for_initialization_assignment
    code = "int a = 1;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, function_analyzer.assignments
  end

  def test_finds_zero_assignments_for_const_assignment
    code = "const int a = 2;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 0, function_analyzer.assignments
  end

  def test_finds_one_assignment_for_multiply_assignment
    code = "a *= 2;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, function_analyzer.assignments
  end

  def test_finds_one_assignment_for_divide_assignment
    code = "a /= 2;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, function_analyzer.assignments
  end

  def test_finds_one_assignment_for_modulo_assignment
    code = "a %= 2;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, function_analyzer.assignments
  end

  def test_finds_one_assignment_for_addition_assignment
    code = "a += 2;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, function_analyzer.assignments
  end

  def test_finds_one_assignment_for_subtraction_assignment
    code = "a -= 2;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, function_analyzer.assignments
  end

  def test_finds_one_assignment_for_shift_left_assignment
    code = "a <<= 2;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, function_analyzer.assignments
  end

  def test_finds_one_assignment_for_shift_right_assignment
    code = "a >>= 2;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, function_analyzer.assignments
  end

  def test_finds_one_assignment_for_bitwise_and_assignment
    code = "a &= 2;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, function_analyzer.assignments
  end

  def test_finds_one_assignment_for_bitwise_or_assignment
    code = "a |= 2;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, function_analyzer.assignments
  end

  def test_finds_one_assignment_for_bitwise_not_assignment
    code = "a ^= 2;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, function_analyzer.assignments
  end

  def test_finds_one_assignment_for_pre_increment
    code = "++a;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, function_analyzer.assignments
  end

  def test_finds_one_assignment_for_post_increment
    code = "a++;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, function_analyzer.assignments
  end

  def test_finds_one_assignment_for_pre_decrement
    code = "--a;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, function_analyzer.assignments
  end

  def test_finds_one_assignment_for_post_decrement
    code = "a--;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, function_analyzer.assignments
  end
end
