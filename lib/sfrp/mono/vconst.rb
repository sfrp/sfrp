module SFRP
  module Mono
    class VConst
      attr_reader :str

      def initialize(str, type_str, arg_type_strs, native_str = nil)
        @str = str
        @type_str = type_str
        @arg_type_strs = arg_type_strs
        @native_str = native_str
      end

      def comp
        [@str, @type_str, @arg_type_strs, @native_str]
      end

      def ==(other)
        comp == other.comp
      end

      # Return max memory size to hold an instance of this vconst.
      def memory(set)
        @arg_type_strs.reduce(Memory.empty) do |m, t_str|
          m.and(set.type(t_str).memory(set))
        end
      end

      # Is this vconst expressed in native C value?
      def native?
        @native_str
      end

      def native_args?(set)
        @arg_type_strs.all? { |s| set.type(s).native? }
      end

      # Generate a struct-element of term for this vconst.
      def gen_term_definition(set, term_id, terms)
        return if native?
        terms << L.member_structure('struct', "term#{term_id}") do |term|
          @arg_type_strs.each_with_index do |t_str, idx|
            low_type_str = set.type(t_str).low_type_str
            term << L.member("#{low_type_str} member#{idx}")
          end
        end
      end

      # Do elements of this vconst need marking?
      def param_needing_mark?(set)
        @arg_type_strs.any? { |type_str| set.type(type_str).need_mark?(set) }
      end

      # Generate constructor-function in C.
      def gen_constructor(src_set, term_id, dest_set)
        return if native?
        type = src_set.type(@type_str)
        dest_set << L.function(low_constructor_str, type.low_type_str) do |f|
          @arg_type_strs.each_with_index.map do |t_str, mem_idx|
            f.append_param(src_set.type(t_str).low_type_str, "member#{mem_idx}")
          end
          if type.static?
            f << L.stmt("#{type.low_type_str} x")
          else
            f << L.stmt("#{type.low_type_str} x = #{type.low_allocator_str}(0)")
          end
          if type.has_meta_in_struct?
            f << L.stmt("#{type.meta_access_str('x')}.term_id = #{term_id}")
          end
          @arg_type_strs.size.times do |mem_idx|
            terms = type.terms_access_str('x')
            m = "member#{mem_idx}"
            f << L.stmt("#{terms}.term#{term_id}.#{m} = #{m}")
          end
          f << L.stmt('return x')
        end
      end

      # return low-expression to make a new instance by this vconst
      def low_constructor_call_exp(low_arg_exps)
        return @native_str if native?
        "#{low_constructor_str}(#{low_arg_exps.join(', ')})"
      end

      # Return conditional-low-exps to match this vconst and receiver-exp.
      def low_compare_exps(set, receiver_exp)
        type = set.type(@type_str)
        return [] if type.single_vconst?
        return ["#{receiver_exp} == #{@native_str}"] if native?
        meta = type.meta_access_str(receiver_exp)
        term_id = type.term_id(@str)
        ["#{meta}.term_id == #{term_id}"]
      end

      # name of constructor-function in C for this vconst
      def low_constructor_str
        'VC_' + @str
      end

      # Return alias of the constructor of this vconst.
      def low_macro_for_alias(alias_str)
        arg = ('a'..'z').take(@arg_type_strs.size).join(', ')
        L.macro("#{alias_str}(#{arg}) #{low_constructor_str}(#{arg})")
      end

      # Return low-exp to mark elements of this vconst.
      def low_mark_element_exps(set, term_id, receiver_str)
        types = @arg_type_strs.map { |t_str| set.type(t_str) }
        types_needing_mark = types.select { |t| t.need_mark?(set) }
        types_needing_mark.each_with_index.map do |type, mem_idx|
          term_access = "#{type.terms_access_str(receiver_str)}.term#{term_id}"
          "#{type.low_mark_func_str}(#{term_access}.member#{mem_idx})"
        end
      end

      def low_member_pointers(type, receiver_str)
        term_id = type.term_id(@str)
        terms_access = "#{type.terms_access_str(receiver_str)}.term#{term_id}"
        @arg_type_strs.each_with_index.map do |_, mem_idx|
          "&#{terms_access}.member#{mem_idx}"
        end
      end
    end
  end
end
