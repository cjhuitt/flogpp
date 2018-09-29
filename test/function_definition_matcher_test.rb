require 'minitest/autorun'
require_relative '../lib/function_definition_matcher'

class FunctionDefinitionMatcherTest < Minitest::Test
  def test_empty_block
    code = <<-CODE
    CODE
    matcher = FunctionDefinitionMatcher.new code
    refute matcher.passes?
    assert_nil matcher.name
  end

  def test_function_declaration
    code = <<-CODE
      void foo();
    CODE
    matcher = FunctionDefinitionMatcher.new code
    refute matcher.passes?
    assert_nil matcher.name
  end

  def test_simple_function_definition
    code = <<-CODE
      void foo() { }
    CODE
    matcher = FunctionDefinitionMatcher.new code
    assert matcher.passes?
    assert_equal "foo", matcher.name
  end

  def test_simple_function_definition_split_across_lines
    code = <<-CODE
      void
        foo
        ( )

        {
        }
    CODE
    matcher = FunctionDefinitionMatcher.new code
    assert matcher.passes?
    assert_equal "foo", matcher.name
  end
end

