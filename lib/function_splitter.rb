require_relative "function"
require_relative "function_definition_matcher"

class FunctionSplitter
  attr_reader :functions

  def initialize filename, code
    chunks = code.split /({|})/
    state = OutsideFunctionState.new filename

    chunks.each do |chunk|
      state = state.process chunk
    end
    @functions = state.functions
  end

  private
    class FunctionState
      attr_reader :filename
      attr_reader :current_line
      attr_reader :functions

      def initialize filename, functions, current_line
        @filename = filename
        @functions = functions
        @current_line = current_line
      end

      def self.CountLines code
        lines = code.lines.count - 1
        lines += 1 if code[-1] == "\n"
        lines
      end
    end

    class OutsideFunctionState < FunctionState
      attr_reader :code

      def initialize filename, functions=Array.new, current_line=1, code=String.new
        super filename, functions, current_line
        @code = code
      end

      def process new_code
        count_lines(new_code).transition new_code
      end

      def count_lines new_code
        lines = @current_line + FunctionState::CountLines(new_code)
        OutsideFunctionState.new @filename, @functions, lines, @code
      end

      def transition new_code
        function_name = find_function_name
        return to_inside function_name if function_name
        add_code new_code
      end

      def find_function_name
        matcher = FunctionDefinitionMatcher.new @code
        return nil if not matcher.passes?
        matcher.name
      end

      def to_inside function_name
        InsideFunctionState.new @filename, @functions, @current_line,
                function_name, @current_line
      end

      def add_code new_code
        OutsideFunctionState.new @filename, @functions, @current_line,
                @code + new_code
      end
    end

    class InsideFunctionState < FunctionState
      attr_reader :function_name
      attr_reader :startline
      attr_reader :nest_level
      attr_reader :contents

      def initialize filename, functions, current_line, function_name, startline, nest_level=1, contents=String.new
        super filename, functions, current_line
        @function_name = function_name
        @startline = startline
        @contents = contents
        @nest_level = nest_level
      end

      def process new_code
        count_lines(new_code).transition new_code
      end

      def count_lines new_code
        lines = @current_line + FunctionState::CountLines(new_code)
        InsideFunctionState.new @filename, @functions, lines, @function_name,
                @startline, @nest_level, @contents
      end

      def transition new_code
        if InsideFunctionState::IsOpening new_code
          return handle_open new_code
        elsif InsideFunctionState::IsClosing new_code
          return handle_close new_code
        else
          return add_code new_code
        end
      end

      def handle_open new_code
        InsideFunctionState.new @filename, @functions, @current_line,
                @function_name, @startline,
                @nest_level + 1, @contents + new_code
      end

      def handle_close new_code
        state = handle_interior_close new_code
        return state.to_outside if state.nest_level == 0
        state.add_code new_code
      end

      def add_code new_code
        InsideFunctionState.new @filename, @functions, @current_line,
                @function_name, @startline,
                @nest_level, @contents + new_code
      end

      def handle_interior_close new_code
        InsideFunctionState.new @filename, @functions, @current_line,
                @function_name, @startline,
                @nest_level - 1,
                @nest_level == 1 ? @contents : @contents + new_code
      end

      def to_outside
        OutsideFunctionState.new @filename, @functions + [extract_function],
                @current_line
      end

      def extract_function
        Function.new function_name, @filename, @startline, @contents
      end

      def self.IsOpening code
        code == '{'
      end

      def self.IsClosing code
        code == '}'
      end
    end
end
