#!/usr/bin/env ruby

require_relative 'database'

module TestExecution
  def self.list_test_executions(debug, dbParam)
    sqlIf = CoverageDatabase::MySqlIf.new( debug, dbParam)
    begin
      sqlIf.updateUsageStats(:list_request)
      sqlIf.printTestRuns(nil)
    ensure
      sqlIf.closeCon
    end
  end

  def self.list_test_suites(debug, dbParam)
    sqlIf = CoverageDatabase::MySqlIf.new( debug, dbParam)
    begin
      sqlIf.updateUsageStats(:list_request)
      sqlIf.printTestsuites(nil)
    ensure
      sqlIf.closeCon
    end
  end


end
