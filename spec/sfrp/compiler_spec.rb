require 'spec_helper'
require 'sfrp/compiler'

module SFRP
  describe 'Compiler' do
    let(:compiler) do
      Compiler.new('Test', [File.dirname(__FILE__)])
    end

    it 'compiles .sfrp to .c' do
      Dir.mktmpdir do |dirpath|
        compiler.compile(dirpath)
        # puts out = File.read(dirpath + '/main.c')
      end
    end
  end
end
