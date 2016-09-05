require 'sfrp/input/set'
require 'sfrp/raw/set'
require 'sfrp/flat/set'
require 'sfrp/poly/set'
require 'sfrp/mono/set'
require 'sfrp/low/set'
require 'sfrp/output/set'
require 'sfrp/error'
require 'sfrp/file'

module SFRP
  class Compiler
    def initialize(main_fmodule_uri, include_paths)
      @main_fmodule_uri = main_fmodule_uri
      @include_paths = include_paths
    end

    def make_input_set
      Input::Set.new do |s|
        collect_fmodule_uris(@main_fmodule_uri).each do |uri|
          content = File.read(to_full_path(uri))
          s.append_source_file(uri, content)
        end
      end
    end

    def make_output_set
      make_input_set
      .to_raw
      .to_flat
      .to_poly
      .to_mono
      .to_low(collect_include_strs(@main_fmodule_uri))
      .to_output
    end

    def compile(output_dir_path = nil)
      virtual_files = collect_virtual_files(@main_fmodule_uri)
      output_set = make_output_set
      output_set.generate!(output_dir_path, virtual_files) if output_dir_path
      output_file_names
    end

    def output_file_names
      ['main'] + collect_virtual_files(@main_fmodule_uri).flat_map do |vf|
        vf.file_ext == 'c' ? [vf.fmodule_uri.gsub('.', '/')] : []
      end
    end

    private

    def collect_fmodule_uris(fmodule_uri, visited = {})
      return [] if visited.key?(fmodule_uri)
      visited[fmodule_uri] = true
      content = File.read(to_full_path(fmodule_uri))
      content.each_line.each_with_object([fmodule_uri]) do |line, ary|
        line.match(/import ([A-Z][a-zA-Z0-9]+(\.[A-Z][a-zA-Z0-9]+)*)/) do |m|
          ary.concat(collect_fmodule_uris(m[1], visited))
        end
      end
    end

    def collect_virtual_files(fmodule_uri)
      collect_fmodule_uris(fmodule_uri).each_with_object([]) do |uri, ary|
        path = to_full_path(uri)
        cpath = path.gsub(/\.sfrp$/, '.c')
        hpath = path.gsub(/\.sfrp$/, '.h')
        if File.exist?(cpath)
          ary << VirtualFile.new(uri, 'c', File.read(cpath))
        end
        if File.exist?(hpath)
          ary << VirtualFile.new(uri, 'h', File.read(hpath))
        end
      end
    end

    def collect_include_strs(fmodule_uri)
      collect_virtual_files(fmodule_uri).each_with_object([]) do |vf, ary|
        if vf.file_ext == 'h'
          ary << "#{vf.fmodule_uri.gsub('.', '/')}.#{vf.file_ext}"
        end
      end
    end

    def to_full_path(fmodule_uri)
      relative_path = fmodule_uri.gsub('.', '/')
      @include_paths.each do |path|
        full_path = path + '/' + relative_path + '.sfrp'
        return full_path if File.exist?(full_path)
      end
      raise FileResolveError.new(fmodule_uri, @include_paths)
    end
  end
end
