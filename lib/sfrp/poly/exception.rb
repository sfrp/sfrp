require 'sfrp/error'

module SFRP
  module Poly
    class UndeterminableTypeError < CompileError
      def initialize(identifier, typing)
        @identifier = identifier
        @typing = typing
      end

      def message
        "undeterminable type #{@typing}"
      end
    end

    class UnifyError < CompileError
      def initialize(typing1, typing2)
        @typing1 = typing1
        @typing2 = typing2
      end

      def message
        vars = @typing1.variables + @typing2.variables
        "cannot unify #{@typing1.to_s(vars)} and #{@typing2.to_s(vars)}"
      end
    end

    class RecursiveError < CompileError
      def initialize(node_strs)
        @node_strs = node_strs
      end

      def chain_str
        [*@node_strs, @node_strs[0]].join(' -> ')
      end

      def message
        "recursive node/function path: #{chain_str}"
      end
    end
  end
end
