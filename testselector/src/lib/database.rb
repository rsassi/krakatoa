require 'mysql'

module CoverageDatabase
  #Class which manages the connection to the MySQL server
  class MySqlIf
    #Constructor
    def initialize(debug, dbParam)
      @debug = debug
      host = dbParam['host']
      port = dbParam['port']
      db = dbParam['database']
      login = dbParam['login']
      pass = dbParam['password']
      if(debug)
        puts dbParam
      end
      @con = Mysql.new(host, login, pass, db, port)
    end

    #Function closes connection to MySQL server
    def closeCon()
      @con.close if @con
    end


    # Function returns the ID of the latest test run
    def getLatestTestRuns()
      begin
        sqlQuery = "SELECT MAX(id) FROM testruns"
        if(@debug)
          puts "sqlQuery= #{sqlQuery}"
        end
        rs = @con.query(sqlQuery)
        row = rs.fetch_hash
        testRuns = [ row["MAX(id)"].to_i ]
      rescue Mysql::Error => e
        puts "MySqlIf> Error during MySQL database query: #{e}"
        exit 1
      end
      testRuns
    end

    #Function creates source_file sections for an SQL query
    #Example output
    #( source_files.name = 'file1'
    # OR source_files.name = 'file2'
    # OR source_files.name = 'file3' )
    def createSourceFileSection(filenames)
      sourceFilesSection = ""
      if filenames.kind_of?(Array)
        sourceFilesSection += "( "
        filenames.each_with_index do |file, index|
          if index > 0
            sourceFilesSection += " OR "
          end
          sourceFilesSection += "source_files.name = '#{file}'"
        end
        sourceFilesSection += " )"
      else
        sourceFilesSection = "source_files.name = '#{filenames}'"
      end
      return sourceFilesSection
    end

    # Validates the test execution/run identifiers provided by the user by
    # consulting the database and returns a valid (subset) array of test run
    # identifiers.
    def getActualTestRuns(testRuns)
      sqlQuery= "SELECT id FROM testruns WHERE #{createTestrunWhereClause(testRuns)}"
      if(@debug)
        puts "sqlQuery= #{sqlQuery}"
      end
      result = @con.query(sqlQuery)
      testRunsCopy = Array.new(testRuns)
      actualTestRuns = []
      result.num_rows.times do
        row = result.fetch_hash
        test_run_id = row['id'].to_i
        actualTestRuns.push(test_run_id)
        testRunsCopy.delete(test_run_id)
      end
      if testRunsCopy.length > 0
        puts("Notice: The following test run identifiers are not valid, so they will be ignored: #{testRunsCopy}")
      end
      actualTestRuns
    end

    # Returns an SQL query section, similar to the following example, for
    # the test run/execution identifier selection:
    #   ( testruns.id = '113' OR testruns.id = '114' OR testruns.id = '115' )
    def createTestrunWhereClause(testRuns, idname='testruns.id')
      testrunSection = testRuns.map { |testRun| "#{idname} = \'#{testRun}\'" }
      testrunSection = testrunSection.join(" OR ")
      "( " + testrunSection + " )"
    end

    def createTestrunQuery(whereClause)
      query = %Q[SELECT `testposition` AS 'Test Position',
        FROM_UNIXTIME(`time_added_epoch`, '%Y-%m-%d') AS 'Date',
        `id` AS Testrun,
        `testsuite` AS 'Test Suite',
        `framework` AS 'Framework',
        SUBSTRING(`git_commit`,1,8)  AS 'Commit ID'
        FROM testruns #{whereClause} ORDER BY id]
    end

    # Fetches the information about the last N SmartTest executions, where N
    # is specified by the argument tableLength. Returns an array of hashes,
    # each of which represents an execution.
    def fetchTestRunTableData(testRuns)
      testrunWhereClause=''
      if (testRuns)
        testrunWhereClause = 'WHERE ' + createTestrunWhereClause(testRuns)
      end
      query = createTestrunQuery(testrunWhereClause)
      rows = []
      if(@debug)
        puts "sqlQuery= #{query}"
      end
      @con.query(query) do |result|
        result.num_rows.times.each do |idx|
          rows.push(result.fetch_hash)
        end
      end
      rows
    end

    public

    def fetchTestsuiteTableData(testRuns)
      testsuitesWhereClause=''
      if (testRuns)
        testrunWhereClause = 'WHERE ' + createTestrunWhereClause(testRuns)
      end
      query = %Q[SELECT DISTINCT(`testsuite`) AS 'Test Suite' FROM testruns #{testrunWhereClause} ]
      rows = []
      if(@debug)
        puts "sqlQuery= #{query}"
      end
      @con.query(query) do |result|
        result.num_rows.times.each do |idx|
          rows.push(result.fetch_hash)
        end
      end
      rows
    end

    def getTotalCounts(testRuns)
      totalCounts = Array.new
      begin
        testrunSection = createTestrunWhereClause(testRuns)
        testrunSection = testrunSection.gsub('testruns.id', 'tests.testrun_id')
        sqlQuery = %Q[SELECT tests.testrun_id, COUNT(tests.id) as total_count, SUM(tests.execution_time_secs) as total_time_secs
              FROM tests
              WHERE #{testrunSection}
              GROUP BY tests.testrun_id]
        if(@debug)
          puts "sqlQuery= #{sqlQuery}"
        end
        rs = @con.query(sqlQuery)
        rs.num_rows.times do
          row = rs.fetch_row
          totalCounts.push([row[0], row[1].to_i, row[2].to_i ])
        end
        return totalCounts
      rescue Mysql::Error => e
        puts "MySqlIf> Error during MySQL database query: #{e}"
        exit 1
      end
    end

    def createTestQuery(whereClause)
      sqlQuery = %Q[SELECT tests.path as path, tests.name as name,
              tests.mangled_name, tests.execution_time_secs,
              testruns.id as testrun_id, testruns.testposition, testruns.testsuite
              FROM testruns
              INNER JOIN tests ON testruns.id = tests.testrun_id
              INNER JOIN source_files ON source_files.testrun_id = testruns.id
              INNER JOIN functions ON functions.testrun_id = testruns.id and functions.source_file_id = source_files.id
              INNER JOIN funccov ON funccov.testrun_id = testruns.id and funccov.test_id = tests.id and funccov.function_id = functions.id
              WHERE #{whereClause}
              AND funccov.visited
              GROUP BY testruns.id, testruns.testposition, tests.mangled_name]
    end

    # Function returns the set of test cases associated with the provided filesname
    # by querying the database
    # output : array[][tests.path, tests.name, tests.mangled_name, testruns.testposition ]
    def lookupFilename(filenames, testRuns)
      testNames = Array.new
      if filenames.nil?
        return testNames
      end
      if filenames.kind_of?(Array) and filenames.empty?
        return testNames
      end
      # Get latest test run if it hasn't been specified
      if testRuns.nil?
        testRuns = getLatestTestRuns()
        puts("Notice: Test run identifiers were not specified. Will use the following test executions by default: #{testRuns}")
      else
        testRuns = getActualTestRuns(testRuns)
      end
      begin
        sourceFilesSection = createSourceFileSection(filenames)
        testrunSection = createTestrunWhereClause(testRuns)
        sqlQuery = createTestQuery("#{testrunSection} AND #{sourceFilesSection}")
        if(@debug)
          puts "sqlQuery= #{sqlQuery}"
        end
        rs = @con.query(sqlQuery)
        rs.num_rows.times do
          row = rs.fetch_row
          testNames.push(row)
        end
        return testNames
      rescue Mysql::Error => e
        puts "MySqlIf> Error during MySQL database query: #{e}"
        exit 1
      end
    end

    # Function returns the set of test cases associated with the provided function
    # by querying the database
    def lookupFunctionName(functions, testRuns)
      testNames = Array.new
      if functions.nil? || testRuns.nil?
        return testNames
      end
      begin
        testrunSection = createTestrunWhereClause(testRuns)
        functionSection = createFunctionsWhereClause(functions, 'functions.mangled_name')
        sqlQuery = createTestQuery("#{testrunSection} AND #{functionSection}")
        if(@debug)
          puts "sqlQuery= #{sqlQuery}"
        end
        rs = @con.query(sqlQuery)
        rs.num_rows.times do
          row = rs.fetch_row
          testNames.push(row)
        end
        return testNames
      rescue Mysql::Error => e
        puts "MySqlIf> Error during MySQL database query: #{e}"
        exit 1
      end
    end

    # Returns the list of test runs that match the latest execution of the testSuites.
    def getTestrunsFromTestSuites(testSuites)
      allTestRuns = Array.new
      testSuites.each { |testSuite|
        gitCommit=''
        getCommitQuery = %Q[SELECT `git_commit` FROM testruns WHERE `testsuite`='#{testSuite}'
          ORDER BY time_added_epoch DESC LIMIT 1 ]
        if(@debug)
          puts "sqlQuery= #{getCommitQuery}"
        end
        rs = @con.query(getCommitQuery)
        rs.num_rows.times do
          row = rs.fetch_row
          gitCommit = row[0]
        end
        getTestRunsQuery = %Q[SELECT `id` FROM testruns WHERE `testsuite`='#{testSuite}' AND `git_commit`='#{gitCommit}']
        if (@debug)
          puts getTestRunsQuery
        end
        testRuns = Array.new
        if(@debug)
          puts "sqlQuery= #{getTestRunsQuery}"
        end
        rs = @con.query(getTestRunsQuery)
        rs.num_rows.times do
          row = rs.fetch_row
          testRuns.push(Integer(row[0]))
        end
        allTestRuns.concat(testRuns)
      }
      return allTestRuns
    end

    def getTotalTestCount(testRuns)
      testCount=''
      testRunWhereClause = createTestrunWhereClause(testRuns)
      totalTestCountQuery = %Q[SELECT count(mangled_name) FROM
      (SELECT tests.mangled_name as mangled_name
      FROM testruns
      INNER JOIN tests ON testruns.id = tests.testrun_id
      WHERE #{testRunWhereClause}
      GROUP BY tests.mangled_name
      ) t;]
      if (@debug)
        puts totalTestCountQuery
      end
      rs = @con.query(totalTestCountQuery)
      rs.num_rows.times do
        row = rs.fetch_row
        testCount = row[0]
      end
      return testCount
    end

    # Returns an SQL query section, similar to the following example, for
    # the test run/execution identifier selection:
    #   ( testruns.id = '113' OR testruns.id = '114' OR testruns.id = '115' )
    def createFunctionsWhereClause(functions, name='functions.mangled_name')
      functionSection = functions.map { |function| "(#{name} LIKE \'%#{function.gsub(/::/, '%')}%\')" }
      functionSection = functionSection.join(" OR ")
      "( " + functionSection + " )"
    end

    def getCountOfMatchingFunctions(functions, testRuns)
      functionCount=''
      testrunWhereClause = createTestrunWhereClause(testRuns, 'testrun_id')
      functionSection = createFunctionsWhereClause(functions, 'functions.mangled_name')
      totalfunctionCountQuery = %Q[SELECT count(DISTINCT(mangled_name)) FROM functions
      WHERE #{testrunWhereClause} AND #{functionSection}]
      if (@debug)
        puts totalfunctionCountQuery
      end
      rs = @con.query(totalfunctionCountQuery)
      rs.num_rows.times do
        row = rs.fetch_row
        functionCount = row[0]
      end
      return functionCount
    end

    def updateUsageStats(type)
      list_count     =0
      commit_count   =0
      function_count =0
      calcStr = ''
      case type
      when :list_request
        list_count = 1
        calcStr = 'list_count = list_count + 1'
      when :commit_request
        commit_count   =1
        calcStr = 'commit_count = commit_count + 1'
      when :function_request
        function_count = 1
        calcStr = 'function_count = function_count + 1'
      end
      updateStmt = %Q[INSERT INTO testselector_usage (user, host, list_count, commit_count, function_count, first_visit_epoch, last_visit_epoch)
        VALUES ('#{ENV['USER']}', '#{ENV['HOST']}', '#{list_count}', '#{commit_count}', '#{function_count}', UNIX_TIMESTAMP(NOW()), UNIX_TIMESTAMP(NOW()))
        ON DUPLICATE KEY UPDATE #{calcStr}, last_visit_epoch =UNIX_TIMESTAMP(NOW());]
      if(@debug)
        puts "sqlQuery= #{updateStmt}"
      end
      begin
        @con.query(updateStmt)
      rescue Mysql::Error => e
        if (@debug)
          puts "MySqlIf> Failed to update table  #{e}"
        end
      end
    end

  end
end