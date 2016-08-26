require 'sfrp/error'

module SFRP
  module Input
    class ParseError < CompileError
      def initialize(message)
        @message = message
      end

      def message
        "Syntax error. The raw error message from Parslet is as follows:\n  " +
        @message
      end
    end
  end
end
