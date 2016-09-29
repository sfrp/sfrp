module SFRP
  module Poly
    class Function
      attr_reader :str

      def initialize(str, param_strs, ftype_annot, exp = nil, ffi_str = nil)
        raise ArgumentError if exp.nil? && ffi_str.nil?
        @str = str
        @param_strs = param_strs
        @ftype_annot = ftype_annot
        @exp = exp
        @ffi_str = ffi_str
      end

      def ftyping(set)
        @ftyping ||= @ftype_annot.to_ftyping.instance do |ft|
          var_env = {}
          @param_strs.zip(ft.params) { |str, typing| var_env[str] = typing }
          ft.body.unify(@exp.typing(set, var_env)) if @exp
        end
      end

      def clone
        exp = (@exp ? @exp.clone : nil)
        Function.new(@str, @param_strs, @ftype_annot, exp, @ffi_str)
      end

      def check_recursion(set, path = [])
        return if @exp == nil
        if path.include?(@str)
          raise RecursiveError.new(path.drop_while { |s| s != @str })
        end
        @exp.called_func_strs.each do |str|
          set.func(str).check_recursion(set, path + [@str])
        end
      end

      def to_mono(monofier, mono_func_str)
        raise UndeterminableTypeError.new(@str, @ftyping) unless @ftyping.mono?
        mono_type_str = monofier.use_type(@ftyping.body)
        M.func(mono_type_str, mono_func_str) do |f|
          @param_strs.zip(@ftyping.params) do |str, typing|
            f.param(monofier.use_type(typing), str)
          end
          f.exp { @exp.to_mono(monofier) } if @exp
          f.ffi_str(@ffi_str) if @ffi_str
        end
      end
    end

    class Node
      attr_reader :str

      NodeRef = Struct.new(:node_str, :last)

      def initialize(
        str, node_refs, ftype_annot, eval_func_str, init_func_str = nil
      )
        @str = str
        @node_refs = node_refs
        @ftype_annot = ftype_annot
        @eval_func_str = eval_func_str
        @init_func_str = init_func_str
      end

      def typing(set)
        return @typing if @typing
        @typing = Typing.new
        @ftyping = set.func(@eval_func_str).ftyping(set).instance do |eval_ft|
          @node_refs.zip(eval_ft.params) do |node_ref, typing|
            set.node(node_ref.node_str).typing(set).unify(typing)
          end
          next unless @init_func_str
          @init_ftyping = set.func(@init_func_str).ftyping(set).instance do |ft|
            raise unless ft.params.empty?
            ft.body.unify(eval_ft.body)
          end
        end
        @ftyping.unify(@ftype_annot.to_ftyping).body.unify(@typing)
      end

      def check_recursion(set, path = [])
        if path.include?(@str)
          raise RecursiveError.new(path.drop_while { |s| s != @str })
        end
        @node_refs.each do |nr|
          next if nr.last
          set.node(nr.node_str).check_recursion(set, path + [@str])
        end
      end

      def to_mono(monofier)
        raise UndeterminableTypeError.new(@str, @typing) unless @typing.mono?
        type_str = monofier.use_type(@typing)
        node_str = monofier.use_node(@str)
        eval_func_str = monofier.use_func(@eval_func_str, @ftyping)
        if @init_func_str
          init_func_str = monofier.use_func(@init_func_str, @init_ftyping)
        else
          init_func_str = nil
        end
        M.node(type_str, node_str, eval_func_str, init_func_str) do |n|
          @node_refs.each do |node_ref|
            node_str = monofier.use_node(node_ref.node_str)
            node_ref.last ? n.l(node_str) : n.c(node_str)
          end
        end
      end
    end

    class TConst
      attr_reader :str

      def initialize(
        str, paramc, vconst_strs = nil, static = false, native_str = nil
      )
        @str = str
        @paramc = paramc
        @vconst_strs = vconst_strs
        @static = static
        @native_str = native_str
      end

      def typing
        @typing ||= Typing.new(@str, Array.new(@paramc) { Typing.new })
      end

      def clone
        TConst.new(@str, @paramc, @vconst_strs, @static, @native_str)
      end

      def to_mono(monofier)
        raise UndeterminableTypeError.new(@str, @typing) unless @typing.mono?
        type_str = monofier.use_type(@typing)
        return M.type(type_str, nil, @static, @native_str) unless @vconst_strs
        vconst_strs = @vconst_strs.map { |s| monofier.use_vconst(s, @typing) }
        M.type(type_str, vconst_strs, @static, @native_str)
      end
    end

    class VConst
      attr_reader :str

      def initialize(str, annot_vars, ftype_annot, native_str = nil)
        @str = str
        @annot_vars = annot_vars
        @ftype_annot = ftype_annot
        @native_str = native_str
      end

      def ftyping
        @ftyping ||= @ftype_annot.to_ftyping(@annot_vars)
      end

      def clone
        VConst.new(@str, @annot_vars, @ftype_annot, @native_str)
      end

      def to_mono(monofier)
        raise UndeterminableTypeError.new(@str, @ftyping) unless @ftyping.mono?
        type_str = monofier.use_type(@ftyping.body)
        vconst_str = monofier.use_vconst(@str, @ftyping.body)
        arg_type_strs = @ftyping.params.map { |t| monofier.use_type(t) }
        M.vconst(type_str, vconst_str, arg_type_strs, @native_str)
      end
    end
  end
end
