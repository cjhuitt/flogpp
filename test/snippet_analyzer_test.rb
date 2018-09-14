require 'minitest/autorun'
require_relative '../lib/snippet_analyzer'

class SnippetAnalyzerTest < Minitest::Test
  def test_finds_zero_for_empty_function
    code = "void foo() { }"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal function_analyzer.analyze(), 0
  end
end
