module GenTestSuite
  def self.generateTestSuite(selectedTests, escapeTestNames, outputFile, outputParam)
    # Since at this point there could be many duplicate
    # object file & test pair in the selectedTests, then
    # we should first get rid of those duplicates; this
    # is one (kludgy) way of doing it
    testModules = Array.new
    selectedTests.each do |test|
      testModules.push(test[0])
    end
    testModules.uniq! # Get rid of duplicates

    tests = Array.new
    selectedTests.each do |test|
      tests.push(test[1])
    end
    tests.uniq! # Get rid of duplicates

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

    puts "New  suite created: " + outputFile
  end
end
