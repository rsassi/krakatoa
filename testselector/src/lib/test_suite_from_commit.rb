#!/usr/bin/env ruby

require_relative 'git'
require_relative 'database'
require_relative 'gen_test_suite'

module TestSuiteFromCommit
  # Creates a test suite with the name specified by "outputFile" using the
  # coverage data provided by the executions (the identifiers of which are)
  # specified by the "testRuns" argument for the git commit in the radio
  # repository specified by the "hash" argument.
  def self.create_test_suite(commits, testRuns, testSuites, debug, escapeTestNames, outputFile, dbParam, gitParam, outputParam)

    removePrefix = gitParam['removePrefix']
    replacePrefixWith = gitParam['replacePrefixWith']
    # Then, from each commit get the list of modified files.
    # The current assumptions are that there is no need to regress the
    # deleted file(s), so they wil be excluded. In addition, for new
    # files there is no regression test yet, so they will also be
    # excluded.
    tempStr = String.new
    commitFiles = Array.new
    commits.each do |commit|
      commit = commit.sub("+ ", "")# Remove the leading "+ " from the commit string
      tempStr.clear
      tempStr = `git show --format="format:" --name-only --diff-filter="M" #{commit}`
      commitFiles.concat(tempStr.split "\n")
      # TODO: Handle the empty file string in the array, for now let it
      #       be in the array and it will be ignored
    end

    # For every modified file to be delivered (i.e., the file in the
    # commit(s) that is modiled), check if it exists in the csv file.
    # If it does, then get the corresponding  test(s).
    # TODO: Handle the scenario in which a modified file (in the commit)
    # cannot be found in the csv file.

    #Remove unrelated files to speed-up processing
    selectedFiles = GitWrapper::pruneFileList(commitFiles, gitParam)

    puts "Searching which tests in #{testSuites.to_s} exercise code in one of the following .cc files from #{commits.map{ |x| x[0,16]}}:"
    puts selectedFiles.to_s

    sqlIf = CoverageDatabase::MySqlIf.new(debug, dbParam)

    #Open connection to SQL server
    sqlIf.updateUsageStats(:commit_request)
    # overrides the list of relevant testRuns if testSuites were specified
    if (testRuns.nil?)
      testRuns = sqlIf.getTestrunsFromTestSuites(testSuites);
    end
    if (testRuns.empty?)
      puts "Error: no test run found for criteria"
      exit(1)
    end
    if (debug)
      puts "Using coverage data from:"
      sqlIf.printTestRuns(testRuns)
    end

    #Fetch  tests which execute the files changed in this commit
    selectedTests = sqlIf.lookupFilename(selectedFiles, testRuns)
    fileCount = selectedFiles.size()
    testCount = Integer(sqlIf.getTotalTestCount(testRuns))
    selectedTestsCount = selectedTests.size()
    coverageRatio = sprintf("%3.2f", (selectedTestsCount.to_f/testCount*100.0))
    puts "For #{fileCount} C++ files in commit #{commits.map{ |x| x[0,16]}}, identified #{selectedTestsCount.to_s} relevant tests out of #{testCount.to_s}(#{coverageRatio}%)"

    #Close connection to SQL server
    sqlIf.closeCon

    GenTestSuite::generateTestSuite(selectedTests, escapeTestNames, outputFile, outputParam)
  end
end
