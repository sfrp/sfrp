module SFRP
  module Raw
    class Ref < Struct.new(:relative_name, :qualifier_name)
      def to_s
        return relative_name if qualifier_name.nil?
        qualifier_name + '.' + relative_name
      end
    end

    class Import < Struct.new(:absolute_namespace_name, :qualifier_name)

    end

    class Namespace
      def initialize(absolute_namespace_name, imports)
        @absolute_namespace_name = absolute_namespace_name
        @imports = [Import.new(absolute_namespace_name, nil), *imports]
      end

      def absolute_name(relative_name)
        @absolute_namespace_name + '.' + relative_name
      end

      def search_for_absolute_names(ref)
        @imports.select { |i| i.qualifier_name == ref.qualifier_name }
          .map { |i| i.absolute_namespace_name + '.' + ref.relative_name }
      end
    end
  end
end
