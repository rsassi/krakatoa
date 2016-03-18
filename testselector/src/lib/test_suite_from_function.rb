#!/usr/bin/env ruby

require_relative 'database'
require_relative 'gen_test_suite_mira'

module TestSuiteFromFunction

  # Creates a test suite with the name specified by "outputFile" using the
  # coverage data provided by the executions (the identifiers of which are)
  def self.create_test_suite(functions, testRuns, testSuites, debug, escapeTestNames, outputFile, dbParam, outputParam)
    puts "Searching which tests in #{testSuites.to_s} exercise the functions #{functions}."
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
    matchingFunctionCount = sqlIf.getCountOfMatchingFunctions(functions, testRuns)
    selectedTests = sqlIf.lookupFunctionName(functions, testRuns)
    testCount = Integer(sqlIf.getTotalTestCount(testRuns))
    selectedTestsCount = selectedTests.size()
    coverageRatio = sprintf("%3.2f", (selectedTestsCount.to_f/testCount*100.0))
    puts "For #{matchingFunctionCount} matching functions, identified #{selectedTestsCount.to_s} relevant tests out of #{testCount.to_s}(#{coverageRatio}%)"
    GenTestSuiteMira::generateTestSuite(selectedTests, escapeTestNames, outputFile, outputParam, sqlIf)
    #Close connection to SQL server
    sqlIf.closeCon
  end
end
