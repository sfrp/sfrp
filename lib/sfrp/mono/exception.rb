require 'sfrp/error'

module SFRP
  module Mono
    class InvalidTypeOfFFIError < CompileError
      def initialize(ffi_str)
        @ffi_str = ffi_str
      end

      def message
        "foreign function '#{@ffi_str}' returns invalid type'"
      end
    end
  end
end
