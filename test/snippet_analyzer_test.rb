require 'minitest/autorun'
require_relative '../lib/snippet_analyzer'

class SimpleSnippetAnalyzerTest < Minitest::Test
  def test_finds_zero_for_empty_function
    code = "void foo() { }"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal function_analyzer.score(), 0
  end

  def test_finds_zero_for_return_keyword
    code = "return 37;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal function_analyzer.score(), 0
  end

  def test_finds_zero_for_default_parameters
    code = "void foo( int a = 0, float b = 0.05f ) { }"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal function_analyzer.score(), 0
  end

  def test_finds_zero_for_c_comment
    code = "/* a = foo(); */"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal function_analyzer.score(), 0
  end

  def test_finds_zero_for_cpp_comment
    code = "// a = foo();"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal function_analyzer.score(), 0
  end

  def test_finds_one_for_simple_assignment
    code = "a = 1;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal function_analyzer.score(), 1
  end

  def test_finds_one_for_assignment_from_variable
    code = "a = b;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal function_analyzer.score(), 1
  end

  def test_finds_one_for_initialization_assignment
    code = "int a = 1;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal function_analyzer.score(), 1
  end

  def test_finds_zero_for_const_assignment
    code = "const int a = 2;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal function_analyzer.score(), 0
  end

  def test_finds_one_for_multiply_assignment
    code = "a *= 2;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal function_analyzer.score(), 1
  end

  def test_finds_one_for_divide_assignment
    code = "a /= 2;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal function_analyzer.score(), 1
  end

  def test_finds_one_for_modulo_assignment
    code = "a %= 2;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal function_analyzer.score(), 1
  end

  def test_finds_one_for_addition_assignment
    code = "a += 2;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal function_analyzer.score(), 1
  end

  def test_finds_one_for_subtraction_assignment
    code = "a -= 2;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal function_analyzer.score(), 1
  end

  def test_finds_one_for_shift_left_assignment
    code = "a <<= 2;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal function_analyzer.score(), 1
  end

  def test_finds_one_for_shift_right_assignment
    code = "a >>= 2;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal function_analyzer.score(), 1
  end

  def test_finds_one_for_bitwise_and_assignment
    code = "a &= 2;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal function_analyzer.score(), 1
  end

  def test_finds_one_for_bitwise_or_assignment
    code = "a |= 2;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal function_analyzer.score(), 1
  end

  def test_finds_one_for_bitwise_not_assignment
    code = "a ^= 2;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal function_analyzer.score(), 1
  end

  def test_finds_one_for_pre_increment
    code = "++a;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal function_analyzer.score(), 1
  end

  def test_finds_one_for_post_increment
    code = "a++;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal function_analyzer.score(), 1
  end

  def test_finds_one_for_pre_decrement
    code = "--a;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal function_analyzer.score(), 1
  end

  def test_finds_one_for_post_decrement
    code = "a--;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal function_analyzer.score(), 1
  end

  def test_finds_one_for_regular_function_call
    code = "foo();"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal function_analyzer.score(), 1
  end

  def test_finds_one_for_global_scoped_function_call
    code = "::foo();"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal function_analyzer.score(), 1
  end

  def test_finds_one_for_namespace_scoped_function_call
    code = "::std::foo();"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal function_analyzer.score(), 1
  end

  def test_finds_one_for_instance_function_call
    code = "    a.foo();"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal function_analyzer.score(), 1
  end

  def test_finds_one_for_pointer_function_call
    code = "    a->b->foo();"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal function_analyzer.score(), 1
  end

  def test_finds_one_for_global_scoped_function_call_with_params
    code = "::foo(bar,nullptr);"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal function_analyzer.score(), 1
  end

  def test_finds_one_for_member_function_call_with_params
    code = "    a->b.foo( b, c );"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal function_analyzer.score(), 1
  end
end
