require 'minitest/autorun'
require_relative '../lib/conditional_counter'

class SimpleSnippetConditionCountTest < Minitest::Test
  def test_finds_zero_conditionals_for_empty_function
    code = "void foo() { }"
    conditional_counter = ConditionalCounter.new( code )
    assert_equal 0, conditional_counter.conditionals
  end

  def test_finds_zero_conditionals_for_return_keyword
    code = "return 37;"
    conditional_counter = ConditionalCounter.new( code )
    assert_equal 0, conditional_counter.conditionals
  end

  def test_finds_zero_conditionals_for_default_parameters
    code = "void foo( int a = 0, float b = 0.05f ) { }"
    conditional_counter = ConditionalCounter.new( code )
    assert_equal 0, conditional_counter.conditionals
  end

  def test_finds_zero_conditionals_for_c_comment
    code = "/* a = foo(); */"
    conditional_counter = ConditionalCounter.new( code )
    assert_equal 0, conditional_counter.conditionals
  end

  def test_finds_zero_conditionals_for_cpp_comment
    code = "// a = foo();"
    conditional_counter = ConditionalCounter.new( code )
    assert_equal 0, conditional_counter.conditionals
  end

  def test_finds_one_conditional_for_equality_test
    code = "    a == b"
    conditional_counter = ConditionalCounter.new( code )
    assert_equal 1, conditional_counter.conditionals
  end

  def test_finds_one_conditional_for_inequality_test
    code = "    a!=b"
    conditional_counter = ConditionalCounter.new( code )
    assert_equal 1, conditional_counter.conditionals
  end

  def test_finds_one_conditional_for_greater_or_equal_test
    code = "a>= b"
    conditional_counter = ConditionalCounter.new( code )
    assert_equal 1, conditional_counter.conditionals
  end

  def test_finds_one_conditional_for_lesser_or_equal_test
    code = "a <=b"
    conditional_counter = ConditionalCounter.new( code )
    assert_equal 1, conditional_counter.conditionals
  end

  def test_finds_one_conditional_for_greater_than_test
    code = "    a > b"
    conditional_counter = ConditionalCounter.new( code )
    assert_equal 1, conditional_counter.conditionals
  end

  def test_finds_one_conditional_for_lesser_than_test
    code = "    a < b"
    conditional_counter = ConditionalCounter.new( code )
    assert_equal 1, conditional_counter.conditionals
  end

  def test_finds_one_conditional_for_else
    code = "}else{"
    conditional_counter = ConditionalCounter.new( code )
    assert_equal 1, conditional_counter.conditionals
  end

  def test_finds_one_conditional_for_case
    code = "case FOO:"
    conditional_counter = ConditionalCounter.new( code )
    assert_equal 1, conditional_counter.conditionals
  end

  def test_finds_one_conditional_for_default
    code = "default:"
    conditional_counter = ConditionalCounter.new( code )
    assert_equal 1, conditional_counter.conditionals
  end

  def test_finds_one_conditional_for_try
    code = "try {"
    conditional_counter = ConditionalCounter.new( code )
    assert_equal 1, conditional_counter.conditionals
  end

  def test_finds_one_conditional_for_catch
    code = "} catch( exception& e ) {"
    conditional_counter = ConditionalCounter.new( code )
    assert_equal 1, conditional_counter.conditionals
  end

  def test_finds_one_conditional_for_unary_conditional
    code = "foo"
    conditional_counter = ConditionalCounter.new( code )
    assert_equal 1, conditional_counter.conditionals
  end

  def test_finds_no_conditionals_for_else_if
    code = "    else if ( a )"
    conditional_counter = ConditionalCounter.new code
    assert_equal 0, conditional_counter.conditionals
  end
end
