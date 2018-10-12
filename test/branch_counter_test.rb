require 'minitest/autorun'
require_relative '../lib/branch_counter'

class BranchCounterTest < Minitest::Test
  def test_finds_zero_branches_for_empty_scope
    code = "{ }"
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

  def test_weights_goto_triple
    code = "    goto label;"
    branch_counter = BranchCounter.new( code )
    assert_equal 3, branch_counter.branches
  end

  def test_weights_new_double
    code = "    new AbraCadabra();"
    branch_counter = BranchCounter.new( code )
    assert_equal 2, branch_counter.branches
  end

  def test_weights_delete_double
    code = "    delete pointer;"
    branch_counter = BranchCounter.new( code )
    assert_equal 2, branch_counter.branches
  end

  def test_weights_malloc_double
    code = "a = malloc(20);"
    branch_counter = BranchCounter.new( code )
    assert_equal 2, branch_counter.branches
  end

  def test_weights_aligned_malloc_double
    code = "a = aligned_malloc(20);"
    branch_counter = BranchCounter.new( code )
    assert_equal 2, branch_counter.branches
  end

  def test_weights_free_double
    code = "free(a);"
    branch_counter = BranchCounter.new( code )
    assert_equal 2, branch_counter.branches
  end

  def test_finds_no_branches_for_if
    code = "  if (x == 0) {"
    branch_counter = BranchCounter.new( code )
    assert_equal 0, branch_counter.branches
  end

  def test_finds_no_branches_for_for
    code = "  for (unsigned int i = 1; i < n; ++i) {"
    branch_counter = BranchCounter.new( code )
    assert_equal 0, branch_counter.branches
  end

  def test_finds_both_branches_for_nested_functions
    code = "foo(bar(e));"
    branch_counter = BranchCounter.new( code )
    assert_equal 2, branch_counter.branches
  end

  def test_finds_function_with_cast_parameter
    code = "foo(a, (void*)b);"
    branch_counter = BranchCounter.new( code )
    assert_equal 1, branch_counter.branches
  end

  def test_finds_one_branch_for_function_in_if_after_preprocessor
    code = <<-CODE
#if 1
         if (insertDisk(diskId) == 0)
         {
         }
#endif
    CODE
    branch_counter = BranchCounter.new( code )
    assert_equal 1, branch_counter.branches
  end

  def test_finds_branches_in_else_if_snippet
    code = <<-CODE
      else if (memcmp(ss->fileName, str_id, strlen(str_id)) == 0) {
      }
    CODE
    branch_counter = BranchCounter.new( code )
    assert_equal 2, branch_counter.branches
  end

  def test_finds_one_branch_for_function_in_while_clause
    code = <<-CODE
      while (List_IsEmpty(list)) {
      }
    CODE
    branch_counter = BranchCounter.new( code )
    assert_equal 1, branch_counter.branches
  end
end
