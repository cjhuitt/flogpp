require 'minitest/autorun'
require_relative '../lib/snippet_analyzer'

class SnippetAnalyzerTest < Minitest::Test
  def test_scores_zero_for_empty_scope
    code = "{ }"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 0, snippet_analyzer.overall
  end

  def test_scores_zero_for_return_keyword
    code = "return 37;"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 0, snippet_analyzer.overall
  end

  def test_scores_zero_for_c_comment
    code = "/* a = foo(); */"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 0, snippet_analyzer.overall
  end

  def test_scores_zero_for_cpp_comment
    code = "// a = foo();"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 0, snippet_analyzer.overall
  end

  def test_scores_one_for_simple_assignment
    code = "a = 1;"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, snippet_analyzer.overall
  end

  def test_scores_one_for_assignment_from_variable
    code = "a = b;"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, snippet_analyzer.overall
  end

  def test_scores_one_for_initialization_assignment
    code = "int a = 1;"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, snippet_analyzer.overall
  end

  def test_scores_zero_for_const_assignment
    code = "const int a = 2;"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 0, snippet_analyzer.overall
  end

  def test_scores_one_for_multiply_assignment
    code = "a *= 2;"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, snippet_analyzer.overall
  end

  def test_scores_one_for_divide_assignment
    code = "a /= 2;"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, snippet_analyzer.overall
  end

  def test_scores_one_for_modulo_assignment
    code = "a %= 2;"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, snippet_analyzer.overall
  end

  def test_scores_one_for_addition_assignment
    code = "a += 2;"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, snippet_analyzer.overall
  end

  def test_scores_one_for_subtraction_assignment
    code = "a -= 2;"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, snippet_analyzer.overall
  end

  def test_scores_one_for_shift_left_assignment
    code = "a <<= 2;"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, snippet_analyzer.overall
  end

  def test_scores_one_for_shift_right_assignment
    code = "a >>= 2;"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, snippet_analyzer.overall
  end

  def test_scores_one_for_bitwise_and_assignment
    code = "a &= 2;"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, snippet_analyzer.overall
  end

  def test_scores_one_for_bitwise_or_assignment
    code = "a |= 2;"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, snippet_analyzer.overall
  end

  def test_scores_one_for_bitwise_not_assignment
    code = "a ^= 2;"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, snippet_analyzer.overall
  end

  def test_scores_one_for_pre_increment
    code = "++a;"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, snippet_analyzer.overall
  end

  def test_scores_one_for_post_increment
    code = "a++;"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, snippet_analyzer.overall
  end

  def test_scores_one_for_pre_decrement
    code = "--a;"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, snippet_analyzer.overall
  end

  def test_scores_one_for_post_decrement
    code = "a--;"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, snippet_analyzer.overall
  end

  def test_scores_one_for_regular_function_call
    code = "foo();"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, snippet_analyzer.overall
  end

  def test_scores_one_for_global_scoped_function_call
    code = "::foo();"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, snippet_analyzer.overall
  end

  def test_scores_one_for_namespace_scoped_function_call
    code = "::std::foo();"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, snippet_analyzer.overall
  end

  def test_scores_one_for_instance_function_call
    code = "    a.foo();"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, snippet_analyzer.overall
  end

  def test_scores_one_for_pointer_function_call
    code = "    a->b->foo();"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, snippet_analyzer.overall
  end

  def test_scores_one_for_global_scoped_function_call_with_params
    code = "::foo(bar,nullptr);"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, snippet_analyzer.overall
  end

  def test_scores_one_for_member_function_call_with_params
    code = "    a->b.foo( b, c );"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, snippet_analyzer.overall
  end

  def test_scores_three_for_goto
    code = "    goto label;"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 3, snippet_analyzer.overall
  end

  def test_scores_two_for_new
    code = "    new AbraCadabra();"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 2, snippet_analyzer.overall
  end

  def test_scores_two_for_delete
    code = "    delete pointer;"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 2, snippet_analyzer.overall
  end

  def test_scores_one_for_equality_test
    code = "    a == b"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, snippet_analyzer.overall
  end

  def test_scores_one_for_inequality_test
    code = "    a!=b"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, snippet_analyzer.overall
  end

  def test_scores_one_for_greater_or_equal_test
    code = "a>= b"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, snippet_analyzer.overall
  end

  def test_scores_one_for_lesser_or_equal_test
    code = "a <=b"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, snippet_analyzer.overall
  end

  def test_scores_one_for_greater_than_test
    code = "    a > b"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, snippet_analyzer.overall
  end

  def test_scores_one_for_lesser_than_test
    code = "    a < b"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, snippet_analyzer.overall
  end

  def test_scores_one_for_else
    code = "}else{"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, snippet_analyzer.overall
  end

  def test_scores_one_for_case
    code = "case FOO:"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, snippet_analyzer.overall
  end

  def test_scores_one_for_default
    code = "default:"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, snippet_analyzer.overall
  end

  def test_scores_one_for_try
    code = "try {"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, snippet_analyzer.overall
  end

  def test_scores_one_for_catch
    code = "} catch( exception& e ) {"
    snippet_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, snippet_analyzer.overall
  end
end
