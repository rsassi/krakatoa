# generate list of relevant tests to execute. The file is in Mira format.
require_relative 'database'

module GenTestSuiteMira
  TESTPOSITION_HEADER =  ['Position', 'Test suite', 'Total_TCs', 'Selected_TCs', 'Total(mins)', 'Selected(mins)', 'Savings(mins)','Testrun_id', 'Date_tested']

  def self.printSavings(testposition_hash)
    maxTestsuiteLength = TESTPOSITION_HEADER[1].size
    table = []
    testposition_hash.each  do |key, hash|
      row= [hash['testposition'], hash['testsuite'], hash['total_count'], hash['count'], hash['total_time']/60, hash['execution_time_secs']/60, (hash['total_time'] - hash['execution_time_secs'])/60, key,hash['date_tested'] ]
      table.push(row)
      if ( hash['testsuite'].size > maxTestsuiteLength)
        maxTestsuiteLength = hash['testsuite'].size
      end
    end
    testposition_format = TESTPOSITION_HEADER.map {|str| "%-#{str.size}s" }
    testposition_format[1] = "%-#{maxTestsuiteLength}s"
    testposition_format_str = testposition_format.join(" ")
    # sort by testsuite then testposition
    table = table.sort do |a,b|
      comp = (a[1] <=> b[1])
      comp.zero? ? (a[0] <=> b[0]) : comp
    end
    puts "selected the following tests for each test positions used to collect coverage data:"
    puts(testposition_format_str % TESTPOSITION_HEADER)  # Print out the header
    puts(testposition_format_str % Array.new(TESTPOSITION_HEADER.length, '-'))
    table.each do | row|
      puts(testposition_format_str % row)
    end
  end

  def self.addTotalCounts(sqlIf, testRunsUsed, per_testrun_counts)
    total_counts = sqlIf.getTotalCounts(testRunsUsed)
    total_counts.each do |row|
      testrun_id = row[0]
      if (per_testrun_counts[testrun_id].nil?)
        per_testrun_counts[testrun_id] = {}
        per_testrun_counts[testrun_id]['count'] =0
        per_testrun_counts[testrun_id]['execution_time_secs'] =0
        per_testrun_counts[testrun_id]['testposition'] = row[1]
        per_testrun_counts[testrun_id]['testsuite']  = row[2]
      end
      #-- add the totals:
      per_testrun_counts[testrun_id]['total_count'] = row[3]
      per_testrun_counts[testrun_id]['total_time']  = row[4]
      per_testrun_counts[testrun_id]['date_tested'] = row[5]
    end
  end

  def self.fileMissing(file, warnings)
    fileNotPresent = !File.file?(file)
    if (fileNotPresent)
      warnings.push("Warning: A file wasn't found in the repo. It was renamed or removed since the last time coverage data was collected. File was removed from output: #{file}")
    end
    fileNotPresent
  end
  def self.validateTestModules(testModules)
    warnings = []
    testModules.uniq!
    # check that the file names are still valid
    testModules.delete_if { |file| fileMissing(file, warnings) }
    warnings
  end

  # input:   array[]
  #[tests.path, tests.name, tests.mangled_name,
  # tests.execution_time_secs, testrun_id, testruns.testposition, testruns.testsuite ]
  def self.addTestData(test, per_testrun_counts)
    testrun_id = test[4]
    testposition = test[5]
    testsuite= test[6]
    execution_time_secs = test[3].to_i
    if (per_testrun_counts[testrun_id].nil?)
      per_testrun_counts[testrun_id] = {}
      per_testrun_counts[testrun_id]['count'] =0
      per_testrun_counts[testrun_id]['execution_time_secs'] =0
      per_testrun_counts[testrun_id]['total_count'] = 0
      per_testrun_counts[testrun_id]['total_time']  = 0
    end
    per_testrun_counts[testrun_id]['testposition'] = testposition
    per_testrun_counts[testrun_id]['testsuite']  = testsuite
    per_testrun_counts[testrun_id]['count'] = per_testrun_counts[testrun_id]['count'] + 1
    per_testrun_counts[testrun_id]['execution_time_secs'] = per_testrun_counts[testrun_id]['execution_time_secs'] + execution_time_secs
  end

  def self.generateTestSuite(testRunsUsed, selectedTests, escapeTestNames, outputFile, outputParam, sqlIf)
    per_testrun_counts= {}
    # Since at this point there could be many duplicate
    # object file & test pair in the selectedTests, then
    # we should first get rid of those duplicates; this
    # is one (kludgy) way of doing it
    testModules = Array.new
    tests = Array.new
    selectedTests.each do |test|
      testModules.push(test[0])
      tests.push(test[1])
      addTestData(test, per_testrun_counts)
    end
    tests.uniq!
    warnings = validateTestModules(testModules)
    if (outputFile.nil?)
      outputFile = outputParam['defaultFileName']
    end
    # Write all the test object files first
    st = File.new(outputFile, "w")
    testModules.each do |testFile|
      st.write(testFile.sub(outputParam['removePrefix'], outputParam['replacePrefixWith']) + "\n")
    end
    if (escapeTestNames.nil?)
      escapeTestNames = outputParam['escapeTestNames']
    end
    # Format
    st.write("--example '(\n")
    # Write all the tests
    tests.each_with_index do |test, index|
      if(escapeTestNames)
        st.write(Regexp.escape(test))
      else
        st.write(test)
      end
      if (index != (tests.size - 1))
        st.write("|\n")
      end
    end
    st.write(")$'\n")
    st.close
    if (per_testrun_counts.size > 0)
      addTotalCounts(sqlIf, testRunsUsed, per_testrun_counts)
      printSavings( per_testrun_counts)
    end
    puts "New  suite created: " + outputFile
    warnings.each {|warning| $stderr.puts warning}
  end
end
