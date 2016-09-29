require 'sfrp/error'

module SFRP
  module Mono
    class InvalidTypeOfForeignFunctionError < CompileError
      def initialize(ffi_str)
        @ffi_str = ffi_str
      end

      def message
        "foreign function '#{@ffi_str}' returns invalid type'"
      end
    end

    class IncompleteMatchExpError < CompileError
      def message
        "incomplete match-exp"
      end
    end
  end
end
