require 'spec_helper'
require 'sfrp/low/set'
require 'sfrp/output/set'

module SFRP
  describe 'Compiled Output-Set from Low-Set' do
    let(:oset) do
      set = Low::Set.new do |s|
        s << L.include_ab('hoge.h')
      end
      set.to_output
    end

    it 'has virtual_files' do
      expect(oset.virtual_files).to contain_exactly(
        VirtualFile.new('main', 'c', '#include <hoge.h>'),
      )
    end
  end
end
