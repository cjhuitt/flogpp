require 'minitest/autorun'
require_relative '../lib/function_splitter'

class FunctionSplitterTest < Minitest::Test
  def test_finds_no_functions_for_empty_block
    code = <<-CODE
    CODE
    splitter = FunctionSplitter.new "foo.c", code
    assert_equal 0, splitter.functions.size
  end

  def test_finds_no_functions_for_function_declaration
    code = <<-CODE
      void foo();
    CODE
    splitter = FunctionSplitter.new "foo.c", code
    assert_equal 0, splitter.functions.size
  end

  def test_finds_one_function_for_single_function_definition
    code = <<-CODE
      void foo() { }
    CODE
    splitter = FunctionSplitter.new "foo.c", code
    assert_equal 1, splitter.functions.size
  end

  def test_finds_one_function_for_single_function_definition_split_across_lines
    code = <<-CODE
      void
        foo
        ( )

        {
        }
    CODE
    splitter = FunctionSplitter.new "foo.c", code
    assert_equal 1, splitter.functions.size
  end

  def test_finds_two_functions_for_two_function_definitions
    code = <<-CODE
      void foo() { }
      void bar() { }
    CODE
    splitter = FunctionSplitter.new "foo.c", code
    assert_equal 2, splitter.functions.size
  end

  def test_finds_one_functions_when_nested
    code = <<-CODE
      void foo() {
          if ( bar ) {
          }
          if ( baz ) {
          }
      }
    CODE
    splitter = FunctionSplitter.new "foo.c", code
    assert_equal 1, splitter.functions.size
  end

  def test_discards_non_function_name
    code = <<-CODE
      #include "bar.h"
      void foo() { }
    CODE
    splitter = FunctionSplitter.new "foo.c", code
    assert_equal "foo", splitter.functions.first.name
  end

  def test_finds_function_start_line
    code = <<-CODE
      #include "bar.h"
      #include "baz.h"
      #include "foo.h"

      namespace {
      }

      void foo() { }
    CODE
    splitter = FunctionSplitter.new "foo.c", code
    assert_equal 8, splitter.functions.first.line
  end

  def test_finds_second_function_start_line
    code = <<-CODE
      #include "bar.h"
      #include "baz.h"
      #include "foo.h"

      namespace {
      }

      void foo() { }

      void bar()
      {
      }
    CODE
    splitter = FunctionSplitter.new "foo.c", code
    assert_equal 11, splitter.functions[1].line
  end

  def test_skips_function_declaration
    code = <<-CODE
      void bar();
      void foo()
      {
        bar();
      }

      void bar() { }
    CODE
    splitter = FunctionSplitter.new "foo.c", code
    assert_equal 2, splitter.functions.size
  end

  def test_remembers_function_contents
    code = <<-CODE
      void foo()
      {
        bar();
      }
    CODE
    splitter = FunctionSplitter.new "foo.c", code
    assert splitter.functions.first.contents.include? "bar();"
    refute splitter.functions.first.contents.include? "{"
    refute splitter.functions.first.contents.include? "}"
  end

  def test_remembers_filename
    code = <<-CODE
      void foo() { }
    CODE
    splitter = FunctionSplitter.new "foo.c", code
    assert_equal "foo.c", splitter.functions.first.filename
  end
end

