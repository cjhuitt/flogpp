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

  def test_function_definition_with_pointer_type
    code = <<-CODE
      void *handleHttpClients(void *data)
      {
    CODE
    matcher = FunctionDefinitionMatcher.new code
    assert matcher.passes?
    assert_equal "handleHttpClients", matcher.name
  end

  def test_function_definition_with_previous_declaration
    code = <<-CODE
      void *diskWorker(void *vdisk);
      pthread_t createThread(void *(*start_routine) (void *), void *arg)
      {
    CODE
    matcher = FunctionDefinitionMatcher.new code
    assert matcher.passes?
    assert_equal "createThread", matcher.name
  end

  def test_function_definition_with_parenthetic_comment
    code = <<-CODE
      /*
      modification, are permitted (subject to the limitations in the
      disclaimer below) provided that the following conditions are met:
      */

      pthread_t createThread(void *(*start_routine) (void *), void *arg)
      {
    CODE
    matcher = FunctionDefinitionMatcher.new code
    assert matcher.passes?
    assert_equal "createThread", matcher.name
  end
end

