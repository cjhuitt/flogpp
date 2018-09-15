require 'minitest/autorun'
require_relative '../lib/snippet_analyzer'

class SimpleSnippetConditionCountTest < Minitest::Test
  def test_finds_zero_conditionals_for_empty_function
    code = "void foo() { }"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 0, function_analyzer.conditionals
  end

  def test_finds_zero_conditionals_for_return_keyword
    code = "return 37;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 0, function_analyzer.conditionals
  end

  def test_finds_zero_conditionals_for_default_parameters
    code = "void foo( int a = 0, float b = 0.05f ) { }"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 0, function_analyzer.conditionals
  end

  def test_finds_zero_conditionals_for_c_comment
    code = "/* a = foo(); */"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 0, function_analyzer.conditionals
  end

  def test_finds_zero_conditionals_for_cpp_comment
    code = "// a = foo();"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 0, function_analyzer.conditionals
  end

  def test_finds_one_conditional_for_equality_test
    code = "    a == b"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, function_analyzer.conditionals
  end

  def test_finds_one_conditional_for_inequality_test
    code = "    a!=b"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, function_analyzer.conditionals
  end

  def test_finds_one_conditional_for_greater_or_equal_test
    code = "a>= b"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, function_analyzer.conditionals
  end

  def test_finds_one_conditional_for_lesser_or_equal_test
    code = "a <=b"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, function_analyzer.conditionals
  end

  def test_finds_one_conditional_for_greater_than_test
    code = "    a > b"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, function_analyzer.conditionals
  end

  def test_finds_one_conditional_for_lesser_than_test
    code = "    a < b"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, function_analyzer.conditionals
  end

  def test_finds_one_conditional_for_else
    code = "}else{"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, function_analyzer.conditionals
  end

  def test_finds_one_conditional_for_case
    code = "case FOO:"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, function_analyzer.conditionals
  end

  def test_finds_one_conditional_for_default
    code = "default:"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, function_analyzer.conditionals
  end

  def test_finds_one_conditional_for_try
    code = "try {"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, function_analyzer.conditionals
  end

  def test_finds_one_conditional_for_catch
    code = "} catch( exception& e ) {"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, function_analyzer.conditionals
  end

  def test_finds_one_conditional_for_unary_conditional
    code = "foo"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, function_analyzer.conditionals
  end
end
