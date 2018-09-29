require 'minitest/autorun'
require_relative "../lib/cleaners/comment_cleaner"

class CommentCleanerTest < Minitest::Test
  def test_simple_c_string
    code = <<-CODE
      /* simple test */
    CODE
    cleaned = CommentCleaner::Clean code
    refute cleaned.include? "simple"
  end

  def test_simple_cpp_string
    code = <<-CODE
      // simple test
    CODE
    cleaned = CommentCleaner::Clean code
    refute cleaned.include? "simple"
  end

  def test_multiline_c_string
    code = <<-CODE
      /*
       * simple test
       */
    CODE
    cleaned = CommentCleaner::Clean code
    refute cleaned.include? "simple"
  end

  def test_leaves_non_c_comment
    code = <<-CODE
      foo();
      /* simple test */
      bar();
    CODE
    cleaned = CommentCleaner::Clean code
    assert cleaned.include? "foo();"
    assert cleaned.include? "bar();"
  end

  def test_leaves_non_cpp_comment
    code = <<-CODE
      foo(); // simple test
      bar();
    CODE
    cleaned = CommentCleaner::Clean code
    assert cleaned.include? "foo();"
    assert cleaned.include? "bar();"
  end

  def test_leaves_code_between_c_comments
    code = <<-CODE
      /* simple test */
      foo();
      /* simple test */
    CODE
    cleaned = CommentCleaner::Clean code
    assert cleaned.include? "foo();"
  end

  def test_leaves_code_between_cpp_comments
    code = <<-CODE
      // simple test
      foo(); // simple test
    CODE
    cleaned = CommentCleaner::Clean code
    assert cleaned.include? "foo();"
  end
end
