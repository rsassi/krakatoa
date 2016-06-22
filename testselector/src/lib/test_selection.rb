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
          prunedFiles.push(file)
        end
      end
    end
    return prunedFiles
  end

  # Function: given an array of filenames,
  # will return an array containing only the interesting file names
  def self.renameFileList(files, gitParam )
    renamedFiles = Array.new
    files.each do |file|
      renamedFiles.push(file.sub(gitParam['removePrefix'], gitParam['replacePrefixWith']))
    end
    return renamedFiles
  end

  # Creates a test suite with the name specified by "outputFile" using the
  # coverage data provided by the executions (the identifiers of which are)
  # specified by the "testRuns" argument for the git commit in the radio
  # repository specified by the "hash" argument.
  def self.create_test_suite_from_commit(commits, testSuites, debug, escapeTestNames, outputFile, dbParam, gitParam, outputParam, selectBy, csvFile)
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
    commitFiles = pruneFileList(commitFiles, gitParam)
    if (commitFiles.size == 0)
      $stderr.puts "Error: No C++ files found in commit"
      exit 1
    end
    if selectBy ==  :files
      commitFiles = renameFileList(commitFiles, gitParam)
      puts "Which exercise code in one of the following #{commitFiles.size} files:"
      commitFiles.sort!
      commitFiles.each do |file|
        puts "\t#{file}"
      end
      create_test_suite_from_files(commitFiles, testSuites, debug, escapeTestNames, outputFile, dbParam, outputParam, csvFile, commits)
    elsif selectBy ==  :functions
      commitFunctions = Array.new
      commits.each do |commit|
        modifiedFunctions = GitWrapper::getModifiedFunctions(debug, commit, commitFiles)
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
      create_test_suite_from_functions(commitFunctions, testSuites, debug, escapeTestNames, outputFile, dbParam, outputParam, csvFile, commits)
    else
      $stderr.puts "Error unhandled --select-by"
      exit 1
    end
  end

  # Creates a test suite with the name specified by "outputFile" using the
  # coverage data provided by the executions (the identifiers of which are)
  def self.create_test_suite_from_files(files, testSuites, debug, escapeTestNames, outputFile, dbParam, outputParam, csvFile, commits)
    if files.size ==0
      $stderr.puts "No files found"
    end
    sqlIf = CoverageDatabase::MySqlIf.new(debug, dbParam)
    #Open connection to SQL server
    sqlIf.updateUsageStats(:commit_request)
    testRuns = sqlIf.getTestrunsFromTestSuites(testSuites);
    if (testRuns.empty?)
      $stderr.puts "Error: no test run found for criteria"
      exit(1)
    end
    sqlIf = CoverageDatabase::MySqlIf.new(debug, dbParam)
    sqlIf.updateUsageStats(:file_request)
    selectedTests = sqlIf.lookupFilename(files, testRuns)
    fileCount = files.size()
    puts "For #{fileCount} files,"
    GenTestSuiteMira::generateTestSuite(testRuns, selectedTests, escapeTestNames, outputFile, outputParam, sqlIf, csvFile, commits)
    #Close connection to SQL server
    sqlIf.closeCon
  end

  # Creates a test suite with the name specified by "outputFile" using the
  # coverage data provided by the executions (the identifiers of which are)
  def self.create_test_suite_from_functions(functions, testSuites, debug, escapeTestNames, outputFile, dbParam, outputParam, csvFile, commits)
    if functions.size ==0
      $stderr.puts "No functions found"
    end
    sqlIf = CoverageDatabase::MySqlIf.new(debug, dbParam)
    sqlIf.updateUsageStats(:function_request)
    testRuns = sqlIf.getTestrunsFromTestSuites(testSuites);
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
    GenTestSuiteMira::generateTestSuite(testRuns, selectedTests, escapeTestNames, outputFile, outputParam, sqlIf, csvFile, commits)
    #Close connection to SQL server
    sqlIf.closeCon
  end
end
