module SFRP
  module Mono
    class Environment
      def initialize
        @serial_queue = ('_v00'..'_v99').to_a
        @var_str_to_type_str = {}
      end

      def new_var(type_str)
        var = @serial_queue.shift
        @var_str_to_type_str[var] = type_str
        var
      end

      def add_var(var_str, type_str)
        @var_str_to_type_str[var_str] = type_str
      end

      def each_declared_vars(&block)
        @var_str_to_type_str.each do |var_str, type_str|
          block.call(var_str, type_str)
        end
      end
    end
  end
end
