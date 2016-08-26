require 'sfrp/input/parser'
require 'sfrp/input/transformer'
require 'sfrp/file'

module SFRP
  module Input
    class Set
      def initialize(&block)
        @source_file_h = {}
        block.call(self) if block
      end

      def to_raw
        Raw::Set.new do |dest_set|
          @source_file_h.values.each do |source_file|
            Parser.parse(source_file).each do |element|
              dest_set << element
            end
          end
        end
      end

      # Append a source file and return missing source file names.
      def append_source_file(fmodule_uri, content)
        @source_file_h[fmodule_uri] = SourceFile.new(fmodule_uri, content)
      end
    end
  end
end
