require 'sfrp/compiler'
require 'optparse'

module SFRP
  class Command < Struct.new(:main_file, :out_dir, :show_files, :include_paths)
    def self.from_argv(argv, env)
      option = { :include_paths => [] }
      opt_parser = OptionParser.new do |parse|
        desc = 'show paths of the .c file'
        parse.on('--show-files', desc) do
          option[:show_files] = true
        end
        desc = 'specify output directory (default is ./output)'
        parse.on('--out=DIR_NAME', desc) do |dir|
          option[:out_dir] = dir
        end
        desc = 'add include path'
        parse.on('--include=PATH', desc) do |path|
          option[:include_paths] << path
        end
      end
      rest_args = opt_parser.parse(argv)
      if env['SFRP_INCLUDE']
        option[:include_paths] += env['SFRP_INCLUDE'].split(':')
      end
      if rest_args.size > 1
        STDERR.puts 'invalid target specification'
        exit(1)
      end
      new(
        (rest_args[0] || 'Main').gsub(/\.sfrp$/, ''),
        (option[:out_dir] || 'output').gsub(/\/$/, ''),
        option[:show_files],
        ['.'] + option[:include_paths]
      )
    end

    def run
      outs = Compiler.new(main_file, include_paths).compile(out_dir)
      outs.each { |o| puts out_dir + '/' + o + '.c' } if show_files
    rescue SFRP::CompileError => cerr
      STDERR.puts cerr.message
      exit(1)
    end
  end
end
