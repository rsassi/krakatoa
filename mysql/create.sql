-- DROP DATABASE IF EXISTS smarttestdb;
CREATE DATABASE IF NOT EXISTS smarttestdb;
USE smarttestdb;

-- ----------------------------------------------------------------------
-- A testrun is a single test suite execution.
-- i.e. data gathered by the execution of a testsuite on a certain test position.
-- one row per test suite execution
CREATE TABLE IF NOT EXISTS testruns (
    id INT NOT NULL AUTO_INCREMENT,
    time_added_epoch  INT,
    testposition int, -- identifies which test exquipment was used for testing
    test_results_id int, -- identifies where tests results are stored (pointing outside the smarttestdb)
    git_commit varchar(40), -- git hash of commit under test
    framework varchar(64), -- Framwork used for testing. examples :{Mira, GoogleTest, ...}
    testsuite varchar(64), -- testsuite executed. examples: {regression.mira, smoke.mira, ...}
    never_delete INT DEFAULT 0, -- just a flag for db admin to keep this data forever
    directory_cov_html LONGTEXT, -- populated by dircov project with an html tree of function coverage per directory.
    PRIMARY KEY(id)
) ENGINE=INNODB;

-- ----------------------------------------------------------------------
-- A test is one execution of a test within the context of a testrun
-- IDs are only unique within a testrun
-- one row per test executed, per testrun
CREATE TABLE IF NOT EXISTS  tests (
	testrun_id INT,
	id INT,
	test_group_id INT DEFAULT 0,
	mangled_name TEXT,
	name TEXT,
	execution_time_secs INT DEFAULT 0,
	passed INT DEFAULT 0,
	failed INT DEFAULT 0,
    PRIMARY KEY(testrun_id, id),
    KEY(id),
    FOREIGN KEY(testrun_id, test_group_id) REFERENCES test_groups(testrun_id, id),
    FOREIGN KEY(testrun_id) REFERENCES testruns(id) ON DELETE CASCADE
) ENGINE=INNODB;

-- ----------------------------------------------------------------------
-- A source code file in the application under test
-- IDs are only unique within a testrun
-- This is because all IDs are generated when running gen2covDB.jar
-- In reality testruns performed using the same build target built from 
--  the same git commit could reuse the same IDs but this would 
--  complicate ID allocation significantly.
-- one row per source file, per testrun 
CREATE TABLE IF NOT EXISTS  source_files (testrun_id INT, id INT, name TEXT,
    PRIMARY KEY(testrun_id, id),
    KEY(id), -- add an index for id
    FOREIGN KEY(testrun_id) REFERENCES testruns(id) ON DELETE CASCADE
) ENGINE=INNODB;

-- ----------------------------------------------------------------------
-- A function in the application under test
-- IDs are only unique within a testrun
-- This is because all IDs are generated when running gen2covDB.jar
-- one row per function, per testrun
CREATE TABLE IF NOT EXISTS  functions (testrun_id INT, id INT, source_file_id INT, source_line INT, mangled_name TEXT, name TEXT,
    PRIMARY KEY(testrun_id, id),
    KEY(id),
    FOREIGN KEY(testrun_id, source_file_id)  REFERENCES source_files(testrun_id, id) ON DELETE CASCADE 
) ENGINE=INNODB;

-- ----------------------------------------------------------------------
-- Indicate if a function called during the test.
-- IDs are only unique within a testrun
-- This is because all IDs are generated when running gen2covDB.jar
-- one row per function, per test, per testrun
CREATE TABLE IF NOT EXISTS  funccov (testrun_id INT, test_id INT, function_id INT, `visited` BOOL DEFAULT 0;
    PRIMARY KEY(testrun_id, test_id, function_id),
    FOREIGN KEY(testrun_id, test_id)     REFERENCES tests(testrun_id, id) ON DELETE CASCADE,
    FOREIGN KEY(testrun_id, function_id) REFERENCES functions(testrun_id, id) ON DELETE CASCADE
) ENGINE=INNODB;

-- ----------------------------------------------------------------------
-- Test groups are a logical grouping of tests.
-- They are sometime useful to reduce the scope during analysis of coverage data.
-- IDs are only unique within a testrun
-- one row per test group, per testrun
CREATE TABLE IF NOT EXISTS  test_groups (
    testrun_id INT,
    id INT,
    name TEXT,
    PRIMARY KEY(testrun_id, id),
    FOREIGN KEY(testrun_id) REFERENCES testruns(id) ON DELETE CASCADE
) ENGINE=INNODB;


