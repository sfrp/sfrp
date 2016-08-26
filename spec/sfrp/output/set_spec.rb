require 'spec_helper'
require 'sfrp/output/set'

module SFRP
  describe 'Output-Set' do
    let(:oset) do
      Output::Set.new do |s|
        s.create_file('Hoge.Fuga.Piyo', 'txt', 'I am piyo.')
        s.create_file('Hoge.Fuga.Hina', 'txt', 'I am hina.')
      end
    end

    let(:sample_vf) do
      VirtualFile.new('Hoge', 'txt', 'I am hoge.')
    end

    it 'generates files' do
      Dir.mktmpdir do |dirpath|
        oset.generate!(dirpath, [sample_vf])
        expect(File.open(dirpath + '/Hoge.txt', 'r', &:read))
          .to eql 'I am hoge.'
        expect(File.open(dirpath + '/Hoge/Fuga/Piyo.txt', 'r', &:read))
          .to eql 'I am piyo.'
        expect(File.open(dirpath + '/Hoge/Fuga/Hina.txt', 'r', &:read))
          .to eql 'I am hina.'
      end
    end
  end
end
