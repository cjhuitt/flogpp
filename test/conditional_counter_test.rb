require 'minitest/autorun'
require_relative '../lib/conditional_counter'

class ConditionalCounterTest < Minitest::Test
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
    code = "   if( a == b )"
    conditional_counter = ConditionalCounter.new( code )
    assert_equal 1, conditional_counter.conditionals
  end

  def test_finds_one_conditional_for_inequality_test
    code = "   if( a!=b )"
    conditional_counter = ConditionalCounter.new( code )
    assert_equal 1, conditional_counter.conditionals
  end

  def test_finds_one_conditional_for_greater_or_equal_test
    code = "if(a>= b) "
    conditional_counter = ConditionalCounter.new( code )
    assert_equal 1, conditional_counter.conditionals
  end

  def test_finds_one_conditional_for_lesser_or_equal_test
    code = "if(a <=b)"
    conditional_counter = ConditionalCounter.new( code )
    assert_equal 1, conditional_counter.conditionals
  end

  def test_finds_one_conditional_for_greater_than_test
    code = "  if(  a > b )"
    conditional_counter = ConditionalCounter.new( code )
    assert_equal 1, conditional_counter.conditionals
  end

  def test_finds_one_conditional_for_lesser_than_test
    code = "  if(  a < b )"
    conditional_counter = ConditionalCounter.new( code )
    assert_equal 1, conditional_counter.conditionals
  end

  def test_finds_one_conditional_for_else
    code = "}else{"
    conditional_counter = ConditionalCounter.new( code )
    assert_equal 1, conditional_counter.conditionals
  end

  def test_finds_one_conditional_for_ternary
    code = "a = b() ? c() : d();"
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

  def test_finds_one_conditional_for_unary_if_conditional
    code = "if(foo)"
    conditional_counter = ConditionalCounter.new( code )
    assert_equal 1, conditional_counter.conditionals
  end

  def test_finds_one_conditional_for_unary_while_conditional
    code = "while(foo)"
    conditional_counter = ConditionalCounter.new( code )
    assert_equal 1, conditional_counter.conditionals
  end

  def test_finds_one_conditional_for_else_if_with_unary
    code = "    else if ( a )"
    conditional_counter = ConditionalCounter.new code
    assert_equal 1, conditional_counter.conditionals
  end

  def test_finds_no_conditionals_for_function_call_that_contains_try
    code = "a = ListEntry(b);"
    conditional_counter = ConditionalCounter.new code
    assert_equal 0, conditional_counter.conditionals
  end

  def test_finds_no_conditionals_for_while_0_construct
    code = "do { a(); } while( 0 );"
    conditional_counter = ConditionalCounter.new code
    assert_equal 0, conditional_counter.conditionals
  end

  def test_finds_no_conditionals_for_infinite_for_construct
    code = "for ( ;; )"
    conditional_counter = ConditionalCounter.new code
    assert_equal 0, conditional_counter.conditionals
  end

  def test_finds_unary_conditional_in_compound_if_construct
    code = "if (canRead && cs->bytesReceived == 0)"
    conditional_counter = ConditionalCounter.new code
    assert_equal 2, conditional_counter.conditionals
  end

  def test_finds_unary_conditionals_in_compound_ternary_construct
    code = "a = (unary && conditional == 0) ? b : c;"
    conditional_counter = ConditionalCounter.new code
    assert_equal 2, conditional_counter.conditionals
  end

  def test_finds_multiline_if_clauses
    code =<<-CODE
      if (ss->verb == HTTP_PUT &&
          sscanf(ss->fileName, "/log?%40s&%40s", sDiskId, sId) == 2
          && LogFS_HashSetString(&diskId, sDiskId)
          && LogFS_HashSetString(&id, sId))
    CODE
    conditional_counter = ConditionalCounter.new code
    assert_equal 4, conditional_counter.conditionals
  end

  def test_finds_no_conditionals_inside_a_string
    code =<<-CODE
      "<html>"
    CODE
    conditional_counter = ConditionalCounter.new code
    assert_equal 0, conditional_counter.conditionals
  end

  def test_finds_conditionals_between_strings
    code =<<-CODE
         if (info != NULL) {
            printf("locking fails\n");
            if (!LogFS_HashEquals(LogFS_HashApply(id), getCurrentId(diskId))) {
               printf("id check fails\n");
            }
         }
    CODE
    conditional_counter = ConditionalCounter.new code
    assert_equal 2, conditional_counter.conditionals
  end

  def test_handles_empty_string_prior_to_conditional_inside_string
    code =<<-CODE
         wr("");
         wr("<html><head><title>Not Found</title></head><body><p1>NOT FOUND</p1></body></html>\n");
    CODE
    conditional_counter = ConditionalCounter.new code
    assert_equal 0, conditional_counter.conditionals
  end
end
