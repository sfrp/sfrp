require 'sfrp/error'

module SFRP
  VirtualFile = Struct.new(:fmodule_uri, :file_ext, :content)
  SourceFile = Struct.new(:fmodule_uri, :content)

  class FileResolveError < CompileError
    def initialize(fmodule_uri, include_paths)
      @fmodule_uri = fmodule_uri
      @include_paths = include_paths
    end

    def message
      "cannot find '#{@fmodule_uri}' in include paths:\n" +
      @include_paths.join("\n")
    end
  end
end
