module SFRP
  module Poly
    class Typing
      def initialize(tconst_str = nil, arg_typings = [], &block)
        @tconst_str = tconst_str
        @arg_typings = arg_typings
        @parent = nil
        block.call(self) if block
      end

      def tconst_str
        root == self ? @tconst_str : root.tconst_str
      end

      def unify(other)
        return self if same?(other)
        return root.unify(other) unless root == self
        if variable? && other.variable?
          @parent = other
        elsif variable? && !other.variable?
          raise UnifyError.new(self, other) if occur?(other)
          @parent = other
        elsif !variable? && other.variable?
          other.unify(self)
        else
          unless tconst_str == other.tconst_str && argc == other.argc
            raise UnifyError.new(self, other)
          end
          arg_typings.zip(other.arg_typings) { |a, b| a.unify(b) }
          @parent = other
        end
      end

      def unique_str
        raise unless mono?
        "#{tconst_str}[#{arg_typings.map(&:unique_str).join(', ')}]"
      end

      def mono?
        !variable? && arg_typings.all?(&:mono?)
      end

      def variables
        return [self] if variable?
        arg_typings.flat_map(&:variables)
      end

      def to_type_annot(vars)
        if variable?
          idx = vars.index { |v| v.same?(self) }
          raise unless idx
          TypeAnnotationVar.new('a' + idx.to_s)
        else
          args = arg_typings.map { |t| t.to_type_annot(vars) }
          TypeAnnotationType.new(tconst_str, args)
        end
      end

      def to_s(vars = nil)
        vars ||= variables
        to_type_annot(vars).to_s
      end

      protected

      def root
        @parent ? (@parent = @parent.root) : self
      end

      def argc
        arg_typings.size
      end

      def arg_typings
        root == self ? @arg_typings : root.arg_typings
      end

      def variable?
        tconst_str.nil?
      end

      def same?(other)
        return true if root == other.root
        return false if variable? || other.variable?
        return false unless tconst_str == other.tconst_str && argc == other.argc
        arg_typings.zip(other.arg_typings).all? { |a, b| a.same?(b) }
      end

      def occur?(other)
        raise unless variable?
        return true if same?(other)
        arg_typings.any? { |t| occur?(t) }
      end
    end

    class FuncTyping
      attr_reader :params, :body

      def initialize(param_size, &block)
        @params = Array.new(param_size) { Typing.new }
        @body = Typing.new
        block.call(self) if block
      end

      def to_ftype_annot
        vars = @body.variables + @params.flat_map(&:variables)
        args = @params.map { |t| t.to_type_annot(vars) }
        FuncTypeAnnotation.new(@body.to_type_annot(vars), args)
      end

      def unify(other)
        raise unless @params.size == other.params.size
        @params.zip(other.params) { |a, b| a.unify(b) }
        @body.unify(other.body)
        self
      end

      def instance(&block)
        instance = to_ftype_annot.to_ftyping
        block.call(instance) if block
        instance
      end

      def unique_str
        args = @params + [@body]
        "Func#{@params.size}[#{args.map(&:unique_str).join(', ')}]"
      end

      def mono?
        [@body, *@params].all?(&:mono?)
      end

      def to_s
        to_ftype_annot.to_s
      end
    end

    class FuncTypeAnnotation
      def initialize(ret_type_annot, arg_type_annots)
        @ret_type_annot = ret_type_annot
        @arg_type_annots = arg_type_annots
      end

      def to_ftyping(var_strs = nil)
        var_strs ||= [@ret_type_annot, *@arg_type_annots].flat_map(&:var_strs)
        tbl = Hash[var_strs.uniq.map { |s| [s, Typing.new] }]
        FuncTyping.new(@arg_type_annots.size) do |ft|
          ft.params.zip(@arg_type_annots) { |t, at| t.unify(at.to_typing(tbl)) }
          ft.body.unify(@ret_type_annot.to_typing(tbl))
        end
      end

      def to_s
        "(#{@arg_type_annots.map(&:to_s).join(', ')}) -> #{@ret_type_annot}"
      end
    end

    class TypeAnnotationType
      def initialize(tconst_str, arg_type_annots)
        @tconst_str = tconst_str
        @arg_type_annots = arg_type_annots
      end

      def to_typing(tbl)
        Typing.new(@tconst_str, @arg_type_annots.map { |ta| ta.to_typing(tbl) })
      end

      def var_strs
        @arg_type_annots.flat_map(&:var_strs)
      end

      def to_s
        return @tconst_str if @arg_type_annots.empty?
        "#{@tconst_str}[#{@arg_type_annots.map(&:to_s).join(', ')}]"
      end
    end

    class TypeAnnotationVar
      def initialize(var_str)
        @var_str = var_str
      end

      def to_typing(tbl)
        raise var_str unless tbl.key?(@var_str)
        tbl[@var_str]
      end

      def var_strs
        [@var_str]
      end

      def to_s
        @var_str
      end
    end
  end
end
