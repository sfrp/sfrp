require 'sfrp/compiler'
require 'optparse'

module SFRP
  class Command < Struct.new(
    :main_file, :out_dir, :show_files, :include_paths, :error_class, :cc
  )
    def self.from_argv(argv, env)
      com = new('Main', './output', false, ['.'], false, nil)
      extract_argv(com, argv)
      extract_env(com, env)
      com
    end

    def self.extract_argv(com, argv)
      opt_parser = OptionParser.new do |parse|
        desc = 'show paths of the .c file'
        parse.on('--show-files', desc) do
          com.show_files = true
        end
        desc = 'specify output directory (default is ./output)'
        parse.on('--out=DIR_NAME', desc) do |dir|
          com.out_dir = './' + dir.gsub(/\/$/, '')
        end
        desc = 'add include path (multi specification is allowed)'
        parse.on('--include=PATH', desc) do |path|
          com.include_paths << path
        end
        desc = 'only print error (do not generate compiled file)'
        parse.on('--only-print-error', desc) do
          com.out_dir = nil
        end
        desc = 'print error class instead of error message'
        parse.on('--error-class', desc) do
          com.error_class = true
        end
        desc = 'make binary by given command'
        parse.on('--build=CC', desc) do |cc|
          com.cc = cc
        end
      end
      args_without_option = opt_parser.parse(argv)
      case args_without_option.size
      when 0
        nil
      when 1
        com.main_file = args_without_option[0].gsub(/\.sfrp$/, '')
      else
        STDERR.puts 'invalid target specification'
        exit(1)
      end
    end

    def self.extract_env(com, env)
      if env['SFRP_INCLUDE']
        com.include_paths += env['SFRP_INCLUDE'].split(':')
      end
    end

    def run
      outs = Compiler.new(main_file, include_paths).compile(out_dir)
      out_paths = outs.map { |o| out_dir + '/' + o + '.c' }
      STDOUT.puts out_paths.join("\n") if show_files
      STDERR.print `#{cc} -o #{main_file} #{out_paths.join(' ')}` if cc
    rescue SFRP::CompileError => cerr
      text = error_class ? cerr.class.to_s : cerr.message
      if out_dir == nil
        STDOUT.puts text
        exit(0)
      else
        STDERR.puts text
        exit(1)
      end
    end
  end
end
