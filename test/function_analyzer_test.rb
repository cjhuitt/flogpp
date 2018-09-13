require 'minitest/autorun'

class FunctionAnalyzerTest < Minitest::Test
  def test_finds_zero_for_empty_function
    code = "void foo() { }"
    function_analyzer = FunctionAnalyzer.new( code )
    assert_eq function_analyzer.analyze(), 0
  end
end
