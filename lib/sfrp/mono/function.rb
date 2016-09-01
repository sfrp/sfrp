require 'sfrp/mono/exception'

module SFRP
  module Mono
    class Function
      FType = Struct.new(:param_type_strs, :return_type_str)

      attr_reader :str

      def initialize(str, param_strs, ftype, exp = nil, ffi_str = nil)
        raise ArgumentError if exp.nil? && ffi_str.nil?
        raise ArgumentError unless param_strs.size == ftype.param_type_strs.size
        @str = str
        @param_strs = param_strs
        @ftype = ftype
        @exp = exp
        @ffi_str = ffi_str
      end

      def comp
        [@str, @param_strs, @ftype, @exp, @ffi_str]
      end

      def ==(other)
        comp == other.comp
      end

      # Return max needed memory size to call this function once.
      # If this func is a foreign function, this size is assumed as max needed
      # memory size to hold return-type.
      def memory(set)
        return set.type(@ftype.return_type_str).memory(set) if @ffi_str
        @exp.memory(set)
      end

      # Return low-expression to call this function.
      def low_call_exp(low_arg_exps)
        return L.call_exp(@ffi_str, low_arg_exps) if @ffi_str
        L.call_exp(@str, low_arg_exps)
      end

      def low_call_exp_in_exp(set, env, low_arg_exps)
        if @ffi_str
          type = set.type(@ftype.return_type_str)
          if @ffi_str !~ /[a-zA-Z]/
            if low_arg_exps.size == 2
              return "(#{low_arg_exps[0]}) #{@ffi_str} (#{low_arg_exps[1]})"
            end
            if low_arg_exps.size == 1
              return "#{@ffi_str} (#{low_arg_exps[0]})"
            end
            raise InvalidTypeOfForeignFunctionError.new(@ffi_str)
          end
          if type.native?
            return L.call_exp(@ffi_str, low_arg_exps)
          end
          if type.linear?(set)
            var = env.new_var(@ftype.return_type_str)
            pointers = type.low_member_pointers_for_single_vconst(set, var)
            call_exp = L.call_exp(@ffi_str, low_arg_exps + pointers)
            return "(#{var} = #{type.low_allocator_str}(0), #{call_exp}, #{var})"
          end
          raise InvalidTypeOfForeignFunctionError.new(@ffi_str)
        end
        L.call_exp(@str, low_arg_exps)
      end

      # Generate function in C for this function.
      def gen(src_set, dest_set)
        return if @ffi_str
        env = Environment.new
        type = src_set.type(@ftype.return_type_str)
        dest_set << L.function(@str, type.low_type_str) do |f|
          @param_strs.zip(@ftype.param_type_strs).map do |p_str, t_str|
            f.append_param(src_set.type(t_str).low_type_str, p_str)
          end
          stmt = L.stmt("return #{@exp.to_low(src_set, env)}")
          env.each_declared_vars do |var_str, type_str|
            f << L.stmt("#{src_set.type(type_str).low_type_str} #{var_str}")
          end
          f << stmt
        end
      end
    end
  end
end
