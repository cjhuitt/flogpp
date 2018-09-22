require 'minitest/autorun'
require_relative '../lib/branch_counter'

class SimpleSnippetBranchCountTest < Minitest::Test
  def test_finds_zero_branches_for_empty_function
    code = "void foo() { }"
    branch_counter = BranchCounter.new( code )
    assert_equal 0, branch_counter.branches
  end

  def test_finds_zero_branches_for_return_keyword
    code = "return 37;"
    branch_counter = BranchCounter.new( code )
    assert_equal 0, branch_counter.branches
  end

  def test_finds_zero_branches_for_c_comment
    code = "/* a = foo(); */"
    branch_counter = BranchCounter.new( code )
    assert_equal 0, branch_counter.branches
  end

  def test_finds_zero_branches_for_cpp_comment
    code = "// a = foo();"
    branch_counter = BranchCounter.new( code )
    assert_equal 0, branch_counter.branches
  end

  def test_finds_one_branch_for_regular_function_call
    code = "foo();"
    branch_counter = BranchCounter.new( code )
    assert_equal 1, branch_counter.branches
  end

  def test_finds_one_branch_for_global_scoped_function_call
    code = "::foo();"
    branch_counter = BranchCounter.new( code )
    assert_equal 1, branch_counter.branches
  end

  def test_finds_one_branch_for_namespace_scoped_function_call
    code = "::std::foo();"
    branch_counter = BranchCounter.new( code )
    assert_equal 1, branch_counter.branches
  end

  def test_finds_one_branch_for_instance_function_call
    code = "    a.foo();"
    branch_counter = BranchCounter.new( code )
    assert_equal 1, branch_counter.branches
  end

  def test_finds_one_branch_for_pointer_function_call
    code = "    a->b->foo();"
    branch_counter = BranchCounter.new( code )
    assert_equal 1, branch_counter.branches
  end

  def test_finds_one_branch_for_global_scoped_function_call_with_params
    code = "::foo(bar,nullptr);"
    branch_counter = BranchCounter.new( code )
    assert_equal 1, branch_counter.branches
  end

  def test_finds_one_branch_for_member_function_call_with_params
    code = "    a->b.foo( b, c );"
    branch_counter = BranchCounter.new( code )
    assert_equal 1, branch_counter.branches
  end

  def test_finds_three_branches_for_goto
    code = "    goto label;"
    branch_counter = BranchCounter.new( code )
    assert_equal 3, branch_counter.branches
  end

  def test_finds_two_branches_for_new
    code = "    new AbraCadabra();"
    branch_counter = BranchCounter.new( code )
    assert_equal 2, branch_counter.branches
  end

  def test_finds_two_branches_for_delete
    code = "    delete pointer;"
    branch_counter = BranchCounter.new( code )
    assert_equal 2, branch_counter.branches
  end
end
