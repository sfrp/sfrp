module SFRP
  module Mono
    class Memory
      def self.empty
        Memory.new
      end

      def self.one(type_str)
        Memory.new(type_str => 1)
      end

      def initialize(hash = {})
        @hash = hash
      end

      def and(other)
        Memory.new(@hash.merge(other.hash) { |_, v1, v2| v1 + v2 })
      end

      def or(other)
        Memory.new(@hash.merge(other.hash) { |_, v1, v2| [v1, v2].max })
      end

      def count(type_str)
        @hash[type_str] || 0
      end

      protected
      attr_reader :hash
    end
  end
end
