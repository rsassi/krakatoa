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
TEXT_INDENT = "\n\t\t\t\t\t"

def parse_opts
  #Parse custom options
  options = {}

  begin
    execName ='testselector'
    OptionParser.new do |opts|
      banner = <<END_OF_BANNER
Usage:
  #{execName} --create [options]
  #{execName} --list-test-runs  [options]
  #{execName} --list-test-suites  [options]
END_OF_BANNER

      opts.banner = banner
      options[:select_by] = :files

      opts.on("--create", "Create a test suite. (Optional since this is the default.)") do
        options[:create] = true
      end

      opts.on("--list-test-runs", "List the test runs used to gather coverage data.") do |num_execs|
        options[:list_test_runs] = true
        options[:create] = nil
      end
      opts.on_tail("--list-test-suites", "List all test suites for which we have coverage data.") do
        options[:list_test_suites] = true
        options[:create] = nil
      end

      opts.on("-oFILE", "--out FILE", "Override the name of the test suite file.#{TEXT_INDENT}Only valid with --create.") do |filename|
        options[:output_file] = filename
      end

      opts.on("--modified-files-commit HASH",  Array, "Comma-separated list of git commit identifiers.#{TEXT_INDENT}Selects all tests calling at least one function#{TEXT_INDENT} in one of the modified files.#{TEXT_INDENT}Defaults to HEAD.#{TEXT_INDENT}Only valid with --create.") do |commits|
        options[:commit_ids] = commits
        options[:select_by] = :files
      end

      opts.on("--modified-functions-commit HASH",  Array, "Comma-separated list of git commit identifiers.#{TEXT_INDENT}Selects all tests calling at least one function#{TEXT_INDENT} that was modified in the git commit.#{TEXT_INDENT}Defaults to HEAD.#{TEXT_INDENT}Only valid with --create.") do |commits|
        options[:commit_ids] = commits
        options[:select_by] = :functions
      end

      opts.on("--test-runs a,b,c", Array, "Comma-separated list of identifiers of test executions.#{TEXT_INDENT}Only valid with --create.") do |test_runs|
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

      opts.on("--test-suites a,b,c", Array, "Comma-separated list of test suites.#{TEXT_INDENT}Selects relevant tests from test suites.#{TEXT_INDENT}You can also use the special value 'all'.#{TEXT_INDENT}Only valid with --create.#{TEXT_INDENT}Example: smoke.mira,regression.mira ") do |test_suites|
        test_suites_string = []
        begin
          test_suites.each do |id|
            test_suites_string.push(String(id))
          end
        rescue ArgumentError => ae
          puts "Test suites (#{test_suites}) must be a comma-separated list of strings: #{ae}"
          exit 1
        end
        options[:test_suites] = test_suites_string
      end

      opts.on("--functions f1,f2,f3", Array, "A list of class and/or function names.#{TEXT_INDENT}Selects all tests calling that function.#{TEXT_INDENT}Only valid with --create.") do |functions|
        options[:functions] = functions
      end

      opts.on_tail("-n", "--dont-escape-test-names", "Avoid escaping regular expression characters in test names.#{TEXT_INDENT}WARNING! Only provided to improve human readability.") do
        options[:escapeTestNames] = false
        puts DONT_ESCAPE_TEST_NAMES_WARNING
      end

      opts.on_tail("-d", "--debug", "Output debugging information") do
        options[:debug] = true
      end

      opts.on_tail("-h", "--help", "Show help information") do
        puts opts
        puts "Example: #{execName} --test-suites regression.mira,smoke.mira --id fdca7fbd6d"
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

  if (options[:create].nil? && options[:list_test_runs].nil? && options[:list_test_suites].nil?)
    if (options[:debug])
      puts "Warning: Didn't specify one of: [--list-test-runs | --create ], using default: --create"
    end
    options[:create] = true
  end
  if (options[:create])
    if (options[:test_suites].nil? && options[:test_runs].nil?  )
      if (options[:debug])
        puts "Warning: Didn't specify one of: [ --test-suites | --test-runs ], using default: --test-suites regression.mira"
      end
      options[:test_suites] = ["regression.mira"]
    end
    if (options[:commit_ids].nil? && options[:functions].nil?  )
      if (options[:debug])
        puts "Warning: Didn't specify one of: [ --modified-files-commit | --modified-functions-commit | --functions ], using default: --modified-functions-commit HEAD"
      end
      options[:commit_ids] = [ GitWrapper.getDefaultCommitHash() ]
      options[:select_by] = :functions
    end
  end

  # sanity check:
  if (options[:test_suites] && options[:test_runs])
    STDERR.puts("Error: --test-suites and --test-runs are mutually exclusive.")
    exit 1
  end
  if (options[:commit_ids] && options[:functions])
    STDERR.puts("Error: (--modified-files-commit OR --modified-functions-commit ) is mutually exclusive with --function")
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
