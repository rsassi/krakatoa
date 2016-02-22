-- DROP DATABASE IF EXISTS smarttestdb;
CREATE DATABASE IF NOT EXISTS smarttestdb;
USE smarttestdb;

-- ----------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS testruns (
    id INT NOT NULL AUTO_INCREMENT,
    time_added_epoch  INT, 
    testposition int, -- {139, ...},
    test_results_id int,
    git_commit varchar(40), -- git hash
    framework varchar(64), -- {Mira, Terass, UT, ...}
    testsuite varchar(64), -- {regression.mire, smoke.mira, ...}
        never_delete INT DEFAULT 0,
        directory_cov_html LONGTEXT,
    PRIMARY KEY(id)
) ENGINE=INNODB;

-- ----------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS  tests (testrun_id INT, id INT, mangled_name TEXT, name TEXT,
    PRIMARY KEY(testrun_id, id),
    KEY(id),
    FOREIGN KEY(testrun_id) REFERENCES testruns(id) ON DELETE CASCADE
) ENGINE=INNODB;

-- ----------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS  source_files (testrun_id INT, id INT, name TEXT,
    PRIMARY KEY(testrun_id, id),
    KEY(id), -- add an index for id
    FOREIGN KEY(testrun_id) REFERENCES testruns(id) ON DELETE CASCADE
) ENGINE=INNODB;

-- ----------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS  functions (testrun_id INT, id INT, source_file_id INT, source_line INT, mangled_name TEXT, name TEXT,
    PRIMARY KEY(testrun_id, id),
    KEY(id),
    FOREIGN KEY(testrun_id, source_file_id)     REFERENCES source_files(testrun_id, id) ON DELETE CASCADE 
) ENGINE=INNODB;

-- ----------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS  funccov (testrun_id INT, test_id INT, function_id INT, `visited` BOOL DEFAULT 0;
    PRIMARY KEY(testrun_id, test_id, function_id),
    FOREIGN KEY(testrun_id, test_id)     REFERENCES tests(testrun_id, id) ON DELETE CASCADE,
    FOREIGN KEY(testrun_id, function_id) REFERENCES functions(testrun_id, id) ON DELETE CASCADE
) ENGINE=INNODB;

