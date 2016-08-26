require 'sfrp/low/element'
require 'sfrp/low/dsl'

module SFRP
  module Low
    class Set
      attr_reader :meta, :typedefs, :structs, :functions, :macros, :includes

      def initialize(&block)
        @typedefs = []
        @structs = []
        @functions = []
        @macros = []
        @includes = []
        block.call(self) if block
      end

      def to_output
        Output::Set.new do |dest_set|
          dest_set.create_file('main', 'c', main_file_content)
        end
      end

      def <<(element)
        case element
        when Typedef
          @typedefs << element
        when Structure
          @structs << element
        when Function
          @functions << element
        when Macro
          @macros << element
        when Include
          @includes << element
        else
          raise
        end
      end

      private

      def main_file_content
        elements = []
        @includes.each { |x| elements << x.to_s }
        @macros.each { |x| elements << x.to_s }
        @typedefs.each { |x| elements << x.to_s }
        @structs.each { |x| elements << x.to_s }
        @functions.each do |x|
          elements << x.pretty_code_prototype
        end
        @functions.each { |x| elements << x.to_s }
        elements.join("\n")
      end

      def header_file_content
        elements = []
        elements.join("\n")
      end
    end
  end
end
