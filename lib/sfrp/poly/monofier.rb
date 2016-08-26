module SFRP
  module Poly
    class Monofier
      def initialize(src_set, dest_set, &block)
        @src_set = src_set
        @dest_set = dest_set
        @type_str = {}
        @func_str = {}
        @vconst_str = {}
        @node_str = {}
        block.call(self) if block
      end

      def use_type(typing)
        unique_type_str = typing.tconst_str + '/TYPE/' + typing.unique_str
        if @type_str.key?(unique_type_str)
          @type_str[unique_type_str]
        else
          @type_str[unique_type_str] = 'T' + md5(unique_type_str)
          new_tconst = @src_set.tconst(typing.tconst_str).clone
          new_tconst.typing.unify(typing)
          @dest_set << new_tconst.to_mono(self)
          @type_str[unique_type_str]
        end
      end

      def use_func(func_str, ftyping)
        unique_func_str = func_str + '/FUNC/' + ftyping.unique_str
        if @func_str.key?(unique_func_str)
          @func_str[unique_func_str]
        else
          new_func = @src_set.func(func_str).clone
          mono_func_str = 'F' + md5(unique_func_str)
          new_func.ftyping(@src_set).unify(ftyping)
          @dest_set << new_func.to_mono(self, mono_func_str)
          @func_str[unique_func_str] = mono_func_str
        end
      end

      def use_vconst(vconst_str, typing)
        unique_vconst_str = vconst_str + '/VCONST/' + typing.unique_str
        if @vconst_str.key?(unique_vconst_str)
          @vconst_str[unique_vconst_str]
        else
          @vconst_str[unique_vconst_str] = 'V' + md5(unique_vconst_str)
          new_vconst = @src_set.vconst(vconst_str).clone
          new_vconst.ftyping.body.unify(typing)
          @dest_set << new_vconst.to_mono(self)
          @vconst_str[unique_vconst_str]
        end
      end

      def use_node(node_str)
        unique_node_str = node_str + '/NODE/'
        if @node_str.key?(unique_node_str)
          @node_str[unique_node_str]
        else
          @node_str[unique_node_str] = 'N' + md5(unique_node_str)
        end
      end

      private

      def md5(str)
        require 'digest/md5'
        @record ||= {}
        hash_val = Digest::MD5.hexdigest(str).to_i(16).to_s(36)[0, 20]
        raise "MD5: #{@record[hash_val]} and #{str}" if @record.key?(hash_val)
        hash_val
      end
    end
  end
end
