require 'minitest/autorun'
require_relative '../lib/snippet_analyzer'

class SnippetAnalyzerTest < Minitest::Test
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
end
