#!/usr/bin/env ruby
#
# This file contains the implementation to support the Smarttest's
# test selector.
#
# Essentially, the test selector determines which tests
# are more suitable to be run given the file(s)
# modified in the commit(s) to be delivered.
#

require 'csv'
require 'optparse'

require_relative 'lib/test_selection'
require_relative 'lib/test_execution'
require_relative 'lib/config.rb'

DONT_ESCAPE_TEST_NAMES_WARNING ='WARNING! Using --dont-escape-test-names can cause issues when executing tests. Only provided for improved human readability.'
TEXT_INDENT = "" #"\n\t\t"

def parse_opts
  #Parse custom options
  options = {}

  begin
    execName ='testselector'
    OptionParser.new do |opts|
      banner = <<END_OF_BANNER
Usage:
END_OF_BANNER

      opts.banner = banner
      options[:select_by] = :files
      options[:create] = true
      opts.on_tail("--list-test-suites", "List all test suites for which we have coverage data.") do
        options[:list_test_suites] = true
        options[:create] = false
      end
      opts.on("--select-by-files-modified-in h1,h2,h3",  Array, "Selects tests calling code in one of the files modified in the specified git commits.") do |commits|
        options[:commit_ids] = commits
        options[:select_by] = :files
      end
      opts.on("--select-by-functions-modified-in h1,h2,h3",  Array, "Selects tests calling one of the functions modified in the specified git commits.") do |commits|
        options[:commit_ids] = commits
        options[:select_by] = :functions
      end
      opts.on("--select-from-test-suites a,b,c", Array, "Selects relevant tests from specified test suites.  Special value: all") do |test_suites|
        options[:test_suites] = test_suites
      end
      opts.on("--select-by-functions f1,f2,f3", Array, "Selects tests calling one of the specified function. Only specify name, not the full signature.") do |functions|
        options[:functions] = functions
      end
      opts.on("--select-by-files f1,f2,f3", Array, "Selects tests calling code in one of the specified files.") do |files|
        options[:files] = files
      end
      opts.on("--list-test-runs", "List the test runs used to gather coverage data.") do |num_execs|
        options[:list_test_runs] = true
        options[:create] = false
      end
      opts.on("-oFILE", "--out FILE", "Override the name of the test suite file.") do |filename|
        options[:output_file] = filename
      end
      opts.on("--test-runs a,b,c", Array, "Comma-separated list of identifiers of test executions.") do |test_runs|
        test_runs_int = []
        begin
          test_runs.each do |id|
            test_runs_int.push(Integer(id))
          end
        rescue ArgumentError => ae
          puts "Test run identifiers (#{test_runs}) must be a comma-separated list of integers: #{ae}"
          exit 1
        end
        options[:test_runs] = test_runs_int
      end


      opts.on_tail("-n", "--dont-escape-test-names", "Avoid escaping regular expression characters in test names.#{TEXT_INDENT}WARNING! Only provided to improve human readability.") do
        options[:escapeTestNames] = false
        puts DONT_ESCAPE_TEST_NAMES_WARNING
      end

      opts.on_tail("--debug", "Output debugging information") do
        options[:debug] = true
      end

      opts.on_tail("--force", "Override warnings and run tool anyway.") do
        options[:forced] = true
      end

      opts.on_tail("-h", "--help", "Show help information") do
        puts opts
        puts "Example: #{execName} --select-from-test-suites regression.mira,smoke.mira --select-by-functions-modified-in fdca7fbd6d,5deadbeef3"
        exit 0
      end
    end.parse!

  rescue OptionParser::InvalidOption
    puts $!.to_s
    exit 1
  end

  options
end

if __FILE__ == $PROGRAM_NAME

  startTime = Time.now
  cfg = TestSelectorConfigFile::ConfigReader.new
  @dbParam = cfg.getDB()
  @gitParam = cfg.getGit()
  @outputParam = cfg.getOutput()
  options = parse_opts

  #Default options:
  if (options[:debug].nil?)
    options[:debug]= false
  end
  if (options[:debug])
    puts 'Verbose debug mode enabled'
  end
  if (options[:escapeTestNames].nil?)
    options[:escapeTestNames]= true
  end

  if (options[:create])
    if (options[:test_suites].nil? && options[:test_runs].nil?  )
      if (options[:debug])
        puts "Warning: Didn't specify one of: [ --select-from-test-suites | --test-runs ], using default: --select-from-test-suites regression.mira"
      end
      options[:test_suites] = ["regression.mira"]
    end
    if (options[:commit_ids].nil? && options[:functions].nil?  && options[:files].nil?  )
      if (options[:debug])
        puts "Warning: Didn't specify one of: [ --select-by-files-modified-in | --select-by-functions-modified-in | --select-by-functions | --select-by-files ], using default: --select-by-functions-modified-in HEAD"
      end
      options[:commit_ids] = [ GitWrapper.getDefaultCommitHash() ]
      options[:select_by] = :functions
    end
  end

  # sanity check:
  if (options[:test_suites] && options[:test_runs])
    STDERR.puts("Error: --select-from-test-suites and --test-runs are mutually exclusive.")
    exit 1
  end
  if (options[:commit_ids] && options[:functions])
    STDERR.puts("Error: (--select-by-files-modified-in OR --select-by-functions-modified-in ) is mutually exclusive with --function")
    exit 1
  end

  if (options[:test_suites] && options[:test_suites].include?('all'))
    options[:test_suites] = TestExecution::get_test_suites(options[:debug], @dbParam)
  end
  if options[:create].nil? && options[:list_test_runs].nil? && options[:list_test_suites].nil?
    STDERR.puts("Error: One of {--create, --list-test-runs, --list-test-suites } is mandatory.")
    exit 1
  elsif options[:create] && options[:list_test_runs]
    STDERR.puts("Error: --create and --list-test-runs are mutually exclusive.")
    exit 1
  elsif options[:create]
    # Check to see if preconditions for running script are met
    if !GitWrapper::isInRepo()
      exit 1
    end
    if (!options[:forced] && GitWrapper::uncommittedChangesPresent())
      puts "Error: uncommitted changes will not be used to select tests. Use --force option to ovverride."
      exit 1
    end
    if options[:commit_ids]
      TestSelection::create_test_suite_from_commit(options[:commit_ids], options[:test_runs], options[:test_suites], options[:debug], options[:escapeTestNames], options[:output_file], @dbParam, @gitParam, @outputParam, options[:select_by])
    elsif options[:functions]
      TestSelection::create_test_suite_from_functions(options[:functions], options[:test_runs], options[:test_suites], options[:debug], options[:escapeTestNames], options[:output_file], @dbParam, @outputParam)
    elsif options[:files]
      TestSelection::create_test_suite_from_files(options[:files], options[:test_runs], options[:test_suites], options[:debug], options[:escapeTestNames], options[:output_file], @dbParam, @outputParam)
    end
  elsif options[:list_test_runs]
    TestExecution::list_testruns( options[:debug], @dbParam)
  elsif options[:list_test_suites]
    TestExecution::list_test_suites(options[:debug], @dbParam)
  end
  if (! options[:escapeTestNames])
    puts DONT_ESCAPE_TEST_NAMES_WARNING
  end
  puts "Elapsed time: #{sprintf("%.3f", (Time.now-startTime))} seconds."
end
