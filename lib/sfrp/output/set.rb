require 'sfrp/file'
require 'fileutils'

module SFRP
  module Output
    class Set
      attr_reader :virtual_files

      def initialize(&block)
        @virtual_files = []
        block.call(self) if block
      end

      def generate!(output_dir_path, other_virtual_files = [])
        unless File.directory?(output_dir_path)
          FileUtils.mkdir_p(output_dir_path)
        end
        FileUtils.cd(output_dir_path) do
          (@virtual_files + other_virtual_files).each do |vf|
            relative_path = vf.fmodule_uri.gsub('.', '/') + '.' + vf.file_ext
            dirname = File.dirname(relative_path)
            FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
            File.open(relative_path, 'w') { |f| f.write(vf.content) }
          end
        end
      end

      def create_file(relative_position, file_ext, content)
        @virtual_files << VirtualFile.new(relative_position, file_ext, content)
      end
    end
  end
end
