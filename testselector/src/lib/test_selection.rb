#!/usr/bin/env ruby

require_relative 'git'
require_relative 'database'
require_relative 'gen_test_suite_mira'

module TestSelection
  # Function: given an array of filenames,
  # will return an array containing only the interesting file names
  def self.pruneFileList(files, gitParam )
    includeRegExp = Regexp.union(gitParam['includeFilesRegexp'])
    excludeRegExp = Regexp.union(gitParam['ignoreFilesRegexp'])
    prunedFiles = Array.new
    files.each do |file|
      if (file =~ includeRegExp)
        unless (file =~ excludeRegExp)
          prunedFiles.push(file.sub(gitParam['removePrefix'], gitParam['replacePrefixWith']))
        end
      end
    end
    return prunedFiles
  end
  # Creates a test suite with the name specified by "outputFile" using the
  # coverage data provided by the executions (the identifiers of which are)
  # specified by the "testRuns" argument for the git commit in the radio
  # repository specified by the "hash" argument.
  def self.create_test_suite_from_commit(commits, testRuns, testSuites, debug, escapeTestNames, outputFile, dbParam, gitParam, outputParam, selectBy)
    removePrefix = gitParam['removePrefix']
    replacePrefixWith = gitParam['replacePrefixWith']
    puts "For commits:"
    commits.each do |commit|
      puts "\t #{commit}"
    end
    puts "Searching for tests in:"
    if (testSuites.nil?)
      testRuns.each do |testRun|
        puts "\t#{testRun}"
      end
    else
      testSuites.each do |testsuite|
        puts "\t#{testsuite}"
      end
    end
    if selectBy ==  :files
      # Then, from each commit get the list of modified files.
      # The current assumptions are that there is no need to regress the
      # deleted file(s), so they wil be excluded. In addition, for new
      # files there is no regression test yet, so they will also be
      # excluded.
      commitFiles = Array.new
      commits.each do |commit|
        commitFiles.concat(GitWrapper::getModifiedFiles(debug, commit))
      end
      #Remove unrelated files to speed-up processing
      files = pruneFileList(commitFiles, gitParam)
      if (files.size == 0)
        $stderr.puts "Error: No C++ files found in commit"
        exit 1
      end
      puts "Which exercise code in one of the following #{files.size} files:"
      files.sort!
      files.each do |file|
        puts "\t#{file}"
      end
      create_test_suite_from_files(files, testRuns, testSuites, debug, escapeTestNames, outputFile, dbParam, outputParam)
    elsif selectBy ==  :functions
       commitFunctions = Array.new
       commits.each do |commit|
         modifiedFunctions = GitWrapper::getModifiedFunctions(debug, commit)
         commitFunctions.concat(modifiedFunctions)
       end
      if (commitFunctions.size == 0)
        $stderr.puts "Error: No modified functions found in commit"
        exit 1
      end
      puts "Which exercise code in one of the following #{commitFunctions.size} functions:"
      commitFunctions.sort!
      commitFunctions.each do |function|
         puts "\t#{function}"
       end
       create_test_suite_from_functions(commitFunctions, testRuns, testSuites, debug, escapeTestNames, outputFile, dbParam, outputParam)
    else
      $stderr.puts "Error unhandled --select-by"
      exit 1
    end
  end

  # Creates a test suite with the name specified by "outputFile" using the
  # coverage data provided by the executions (the identifiers of which are)
  def self.create_test_suite_from_files(files, testRuns, testSuites, debug, escapeTestNames, outputFile, dbParam, outputParam)
    if files.size ==0
      $stderr.puts "No files found"
    end
    sqlIf = CoverageDatabase::MySqlIf.new(debug, dbParam)
    #Open connection to SQL server
    sqlIf.updateUsageStats(:commit_request)
    # overrides the list of relevant testRuns if testSuites were specified
    if (testRuns.nil?)
      testRuns = sqlIf.getTestrunsFromTestSuites(testSuites);
    end
    if (testRuns.empty?)
      $stderr.puts "Error: no test run found for criteria"
      exit(1)
    end
    sqlIf = CoverageDatabase::MySqlIf.new(debug, dbParam)
    sqlIf.updateUsageStats(:file_request)
    # overrides the list of relevant testRuns if testSuites were specified
    if (testRuns.nil?)
      testRuns = sqlIf.getTestrunsFromTestSuites(testSuites);
    end
    if (testRuns.empty?)
      puts "Error: no test run found for criteria"
      exit(1)
    end
    selectedTests = sqlIf.lookupFilename(files, testRuns)
    fileCount = files.size()
    puts "For #{fileCount} files,"
    GenTestSuiteMira::generateTestSuite(testRuns, selectedTests, escapeTestNames, outputFile, outputParam, sqlIf)
    #Close connection to SQL server
    sqlIf.closeCon
  end

  # Creates a test suite with the name specified by "outputFile" using the
  # coverage data provided by the executions (the identifiers of which are)
  def self.create_test_suite_from_functions(functions, testRuns, testSuites, debug, escapeTestNames, outputFile, dbParam, outputParam)
    if functions.size ==0
      $stderr.puts "No functions found"
    end
    sqlIf = CoverageDatabase::MySqlIf.new(debug, dbParam)
    sqlIf.updateUsageStats(:function_request)
    # overrides the list of relevant testRuns if testSuites were specified
    if (testRuns.nil?)
      testRuns = sqlIf.getTestrunsFromTestSuites(testSuites);
    end
    if (testRuns.empty?)
      puts "Error: no test run found for criteria"
      exit(1)
    end
    #Fetch  tests which execute the specified function
    matchingFunctions = sqlIf.getMatchingFunctions(functions, testRuns)
    selectedTests = sqlIf.lookupFunctionName(functions, testRuns)
    puts "For #{matchingFunctions.size} matching functions,"
    matchingFunctions.sort!
    matchingFunctions.each do |function|
       puts "\t#{function}"
     end
    GenTestSuiteMira::generateTestSuite(testRuns, selectedTests, escapeTestNames, outputFile, outputParam, sqlIf)
    #Close connection to SQL server
    sqlIf.closeCon
  end
end
