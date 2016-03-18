#!/usr/bin/env ruby

require_relative 'database'

module TestExecution

  # Ugly, but better than iterating over the table twice
  TESTRUN_STR_FORMAT = "%-15s %-10s %-8s %-26s %-10s %-10s"
  # Prints out the SmartTest execution table, as obtained from fetchTestRunTableData
  # in a nicely formatted manner, to the standard output.
  def self.printTestRuns(sqlIf, testRuns)
    rows = sqlIf.fetchTestRunTableData(testRuns)
    return if rows.length == 0
    puts(TESTRUN_STR_FORMAT % rows[0].keys)  # Print out the header
    puts(TESTRUN_STR_FORMAT % Array.new(rows[0].length, '-'))
    rows.each_with_index do |row, idx|
      puts(TESTRUN_STR_FORMAT % row.values)
    end
    testruns = rows.map{ | row| row.map{|key, value| value } }.flatten
  end

  def self.list_testruns(debug, dbParam)
    sqlIf = CoverageDatabase::MySqlIf.new( debug, dbParam)
    begin
      sqlIf.updateUsageStats(:list_request)
      printTestRuns(sqlIf, nil)
    ensure
      sqlIf.closeCon
    end
  end

  def self.printTestsuites(rows)
    return if rows.length == 0
    format_str = "%-20s"
    rows.each_with_index do |row, idx|
      puts(format_str % row.values)
    end
  end

  def self.get_test_suites(debug, dbParam)
    sqlIf = CoverageDatabase::MySqlIf.new( debug, dbParam)
    begin
      sqlIf.updateUsageStats(:list_request)
      rows = sqlIf.fetchTestsuiteTableData(nil)
    ensure
      sqlIf.closeCon
    end
    testsuites = rows.map{ | row| row.map{|key, value| value } }.flatten
  end

  def self.list_test_suites(debug, dbParam)
    sqlIf = CoverageDatabase::MySqlIf.new( debug, dbParam)
    begin
      sqlIf.updateUsageStats(:list_request)
      rows = sqlIf.fetchTestsuiteTableData(nil)
      printTestsuites(rows)
    ensure
      sqlIf.closeCon
    end
  end

end
