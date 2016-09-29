module SFRP
  module Mono
    class Type
      attr_reader :str

      def initialize(str, vconst_strs = nil, static = false, native_str = nil)
        @str = str
        @vconst_strs = vconst_strs
        @static = static
        @native_str = native_str
      end

      def comp
        [@str, @vconst_strs, @static, @native_str]
      end

      def ==(other)
        comp == other.comp
      end

      # Are objects of this type passed through value?
      # Defalut is passing through referrence.
      def static?
        @static
      end

      # Does this type has infinite amount of vconsts?
      def infinite?
        @vconst_strs.nil?
      end

      # Is this type native type?
      def native?
        @native_str
      end

      # Does this type has single vconst of native type parameters
      # e.g. Tuple3(Int, Int, Int)
      def linear?(set)
        single_vconst? && set.vconst(@vconst_strs[0]).native_args?(set)
      end

      # Does this type has only one vconst?
      def single_vconst?
        !infinite? && @vconst_strs.size == 1
      end

      # Do objects of this type need to be passed to mark-function?
      def need_mark?(set)
        return true unless static?
        return false if infinite?
        @vconst_strs.any? { |v_str| set.vconst(v_str).param_needing_mark?(set) }
      end

      def has_meta_in_struct?
        !(static? && single_vconst?)
      end

      def all_pattern_examples(set)
        return [Pattern::PatternExample.new(nil, [])] if infinite?
        @vconst_strs.flat_map do |vc_str|
          set.vconst(vc_str).all_pattern_examples(set)
        end
      end

      # Return max memory size to hold an instance of this type.
      def memory(set)
        return Memory.one(@str) if infinite?
        x = @vconst_strs.reduce(Memory.empty) do |m, v_str|
          m.or(set.vconst(v_str).memory(set))
        end
        Memory.one(@str).and(x)
      end

      def low_typedef_for_alias(alias_str)
        L.typedef("#{low_type_str} #{alias_str}")
      end

      def low_type_str
        @native_str ? @native_str : @str
      end

      def low_allocator_str
        "alloc_#{@str}"
      end

      def low_mark_func_str
        "mark_#{@str}"
      end

      def meta_access_str(receiver_str)
        "#{receiver_str}#{static? ? '.' : '->'}meta"
      end

      def terms_access_str(receiver_str)
        "#{receiver_str}#{static? ? '.' : '->'}terms"
      end

      # Return term-id of given vconst of this type.
      def term_id(vconst_str)
        raise "#{@str} is infinite" if infinite?
        res = @vconst_strs.index(vconst_str)
        raise "#{vconst_str} is not a vconst of #{@str}" unless res
        res
      end

      def low_member_pointers_for_single_vconst(set, receiver_str)
        raise unless single_vconst?
        set.vconst(@vconst_strs[0]).low_member_pointers(self, receiver_str)
      end

      # Generate C's elements for this type.
      def gen(src_set, dest_set)
        gen_struct(src_set, dest_set)
        gen_typedef(src_set, dest_set)
        gen_constructor(src_set, dest_set)
        gen_allocator(src_set, dest_set)
        gen_mark_function(src_set, dest_set)
      end

      # Generate statement to clean up objects of this types.
      def gen_mark_cleanup_stmt(src_set, stmts)
        return unless need_mark?(src_set)
        return if src_set.memory(@str) == 0
        stmts << L.stmt("#{low_allocator_str}(1)")
      end

      private

      # Generate struct for this type.
      def gen_struct(src_set, dest_set)
        return if native? || infinite?
        dest_set << L.struct(@str) do |top|
          if has_meta_in_struct?
            top << L.member_structure('struct', 'meta') do |meta|
              meta << L.member('unsigned char term_id : 7')
              meta << L.member('unsigned char mark : 1')
            end
          end
          top << L.member_structure('union', 'terms') do |terms|
            @vconst_strs.each_with_index do |v_str, term_id|
              vconst = src_set.vconst(v_str)
              vconst.gen_term_definition(src_set, term_id, terms)
            end
          end
        end
      end

      # Generate typedef for this type.
      def gen_typedef(_src_set, dest_set)
        return if native?
        asta = static? ? '' : '*'
        dest_set << L.typedef("struct #{@str}#{asta} #{@str}")
      end

      # Generate constructor-functions for vconsts.
      def gen_constructor(src_set, dest_set)
        return if infinite?
        @vconst_strs.each_with_index do |v_str, term_id|
          src_set.vconst(v_str).gen_constructor(src_set, term_id, dest_set)
        end
      end

      # Generate allocator-function for type.
      def gen_allocator(src_set, dest_set)
        return if static?
        count = src_set.memory(@str)
        memory_var = "memory_#{low_type_str}"
        dest_set << L.function(low_allocator_str, low_type_str) do |f|
          f.append_param('int', 'clean_up')
          f << L.stmt('static int i = 0')
          f << L.stmt("static struct #{low_type_str} #{memory_var}[#{count}]")
          f << L.if_stmt('clean_up') do |if_stmts|
            e = "#{memory_var}[i].meta.mark = 0"
            if_stmts << L.stmt("for (i = 0; i < #{count}; i++) #{e}")
            if_stmts << L.stmt('i = 0')
            if_stmts << L.stmt('return 0')
          end
          f << L.stmt("while (#{memory_var}[i++].meta.mark)")
          f << L.stmt("return #{memory_var} + (i - 1)")
        end
      end

      # Generate mark function for this type.
      def gen_mark_function(src_set, dest_set)
        return unless need_mark?(src_set)
        dest_set << L.function(low_mark_func_str, 'int') do |f|
          f.append_param(low_type_str, 'target')
          f << L.stmt("#{meta_access_str('target')}.mark = 1") unless static?
          @vconst_strs.each_with_index do |v_str, term_id|
            vconst = src_set.vconst(v_str)
            cond_exps = vconst.low_compare_exps(src_set, 'target')
            mark_exps = vconst.low_mark_element_exps(src_set, term_id, 'target')
            next if mark_exps.empty?
            mark_stmt = L.stmt(mark_exps.join(', '))
            if cond_exps.empty?
              f << mark_stmt
            else
              cond_exp = cond_exps.reduce { |a, e| "#{a} && #{e}" }
              f << L.if_stmt(cond_exp) do |i|
                i << mark_stmt
              end
            end
          end
          f << L.stmt('return 0')
        end
      end
    end
  end
end
