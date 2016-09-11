require 'sfrp/error'

module SFRP
  module Flat
    class NodeRefInIllegalPositionError < CompileError
      def initialize(node_str)
        @node_str = node_str
      end

      def message
        "don't refer node '#{@node_str}'"
      end
    end

    class DuplicatedVariableError < CompileError
      def initialize(var_str)
        @var_str = var_str
      end

      def message
        "duplicated variable '#{@var_str}'"
      end
    end

    class UnboundLocalVariableError < CompileError
      def initialize(var_str)
        @var_str = var_str
      end

      def message
        "unbound variable '#{@var_str}'"
      end
    end

    class NodeInvalidLastReferrenceError < CompileError
      def initialize(node_str)
        @node_str = node_str
      end

      def message
        "node '#{@node_str}' should be initialized"
      end
    end
  end
end
