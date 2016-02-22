#!/usr/bin/env ruby

require 'csv'
require 'open3'
require 'optparse'

def parse_options
  options = {}

  OptionParser.new do |opts|
    opts.banner = <<-END_OF_BANNER
    Usage: #{$PROGRAM_NAME} [options]

    Given an ELF file, generate a CSV file that maps mangled function names in the ELF file to the demangled function names.

    END_OF_BANNER

    opts.on("--elf-file ELF_PATH", String, "Path to the ELF file to parse; mandatory.") do |v|
      options[:elf_file] = v
    end

    opts.on("--output-file PATH", String, "The path to the output CSV file; mandatory.") do |v|
      options[:output_file] = v
    end

    opts.on("--nm [NM_PATH]", String, "The path to the \"nm\" binary; optional.") do |v|
      options[:nm] = v
    end
  end.parse!

  if !options.key?(:elf_file)
    STDERR.puts("Mandatory argument: --elf-file")
    exit 1
  elsif !options.key?(:output_file)
    STDERR.puts("Mandatory argument: --output-file")
    exit 1
  end

  if ARGV.length > 0
    STDERR.puts("This script does not accept positional arguments such as #{ARGV}.")
    exit 1
  end

  options
end

def run_and_get_output(*args)
  stdout, stderr, status = Open3.capture3(*args)

  return { :status => status, :stdout => stdout, :stderr => stderr }
end

def get_function_names_from_nm_output(nm_output)
  function_names = []

  nm_output.rstrip.split("\n").each { |line|

    line.rstrip!

    match = line.match(/^[0-9a-fA-F]*\s+\S\s+(.*)$/)

    unless match
      STDERR.puts("Could not parse the following output line from nm: \"#{line}\"")
      exit(1)
    end

    function_names.push(match[1])
  }

  function_names
end

def write_csv_file(output_filename, mangled_names, demangled_names)
  CSV.open(output_filename, "w", { :force_quotes => true }) { |csv|
    mangled_names.zip(demangled_names).each { |pair|
      csv << pair
    }
  }
end

def main
  options = parse_options

  if !options.key?(:nm)
    options[:nm] = '/usr/bin/nm'
  end

  nm_output = run_and_get_output(options[:nm], options[:elf_file])

  if nm_output[:status] != 0 || nm_output[:stderr].length != 0
    STDERR.puts("nm printed errors and/or exited with a non-zero return code. " +
                "Status: #{nm_output[:status]}. Standard error: #{nm_output[:stderr]}")
    exit(1)
  end

  mangled_names = get_function_names_from_nm_output(nm_output[:stdout])

  nm_output = run_and_get_output(options[:nm], "-C", options[:elf_file])

  demangled_names = get_function_names_from_nm_output(nm_output[:stdout])

  write_csv_file(options[:output_file], mangled_names, demangled_names)

  exit 0
end

if __FILE__ == $PROGRAM_NAME
  main
end
