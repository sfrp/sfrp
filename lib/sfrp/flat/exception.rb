require 'sfrp/error'

module SFRP
  module Flat
    class NodeRefInIllegalPositionError < CompileError
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
