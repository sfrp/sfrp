require 'sfrp/error'

module SFRP
  module Raw
    class NameError < CompileError
      def initialize(target_str)
        @target_str = target_str
      end

      def message
        "Cannot resolve '#{@target_str}'"
      end
    end

    class AmbiguousNameError < CompileError
      def initialize(target_str, selection_strs)
        @target_str = target_str
        @selection_strs = selection_strs
      end

      def message
        "Ambiguous name '#{@target_str}':\n" +
        @selection_strs.map { |s| '  ' + s }.join("\n")
      end
    end

    class IllegalSideEffectError < CompileError
      def initialize(target_str)
        @target_str = target_str
      end

      def message
        "Don't call side-effect function '#{@target_str}'"
      end
    end
  end
end
