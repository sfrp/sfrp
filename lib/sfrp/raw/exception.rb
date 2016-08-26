require 'sfrp/error'

module SFRP
  module Raw
    class NameError < CompileError
      def initialize(target_str, source_position)
        @target_str = target_str
        @source_position = source_position
      end

      def message
        @target_str
      end
    end

    class AmbiguousNameError < CompileError
      def initialize(target_str, selection_strs, source_position)
        @target_str = target_str
        @selection_strs = selection_strs
        @source_position = source_position
      end

      def message
        @target_str
      end
    end

    class IllegalSideEffectError < CompileError
      def initialize(target_str, source_position)
        @target_str = target_str
        @source_position = source_position
      end

      def message
        @target_str
      end
    end
  end
end
