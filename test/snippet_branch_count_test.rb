require 'minitest/autorun'
require_relative '../lib/snippet_analyzer'

class SimpleSnippetBranchCountTest < Minitest::Test
  def test_finds_zero_branches_for_empty_function
    code = "void foo() { }"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 0, function_analyzer.branches
  end

  def test_finds_zero_branches_for_return_keyword
    code = "return 37;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 0, function_analyzer.branches
  end

  def test_finds_zero_branches_for_c_comment
    code = "/* a = foo(); */"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 0, function_analyzer.branches
  end

  def test_finds_zero_branches_for_cpp_comment
    code = "// a = foo();"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 0, function_analyzer.branches
  end

  def test_finds_one_branch_for_regular_function_call
    code = "foo();"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, function_analyzer.branches
  end

  def test_finds_one_branch_for_global_scoped_function_call
    code = "::foo();"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, function_analyzer.branches
  end

  def test_finds_one_branch_for_namespace_scoped_function_call
    code = "::std::foo();"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, function_analyzer.branches
  end

  def test_finds_one_branch_for_instance_function_call
    code = "    a.foo();"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, function_analyzer.branches
  end

  def test_finds_one_branch_for_pointer_function_call
    code = "    a->b->foo();"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, function_analyzer.branches
  end

  def test_finds_one_branch_for_global_scoped_function_call_with_params
    code = "::foo(bar,nullptr);"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, function_analyzer.branches
  end

  def test_finds_one_branch_for_member_function_call_with_params
    code = "    a->b.foo( b, c );"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 1, function_analyzer.branches
  end

  def test_finds_three_branches_for_goto
    code = "    goto label;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 3, function_analyzer.branches
  end

  def test_finds_two_branches_for_new
    code = "    new AbraCadabra();"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 2, function_analyzer.branches
  end

  def test_finds_two_branches_for_delete
    code = "    delete pointer;"
    function_analyzer = SnippetAnalyzer.new( code )
    assert_equal 2, function_analyzer.branches
  end
end
