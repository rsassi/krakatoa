use smarttestdb;

ALTER TABLE tests 
ADD COLUMN test_group_id INT DEFAULT 0,
ADD COLUMN execution_time_secs INT DEFAULT 0,
ADD COLUMN passed INT DEFAULT 0,
ADD COLUMN failed INT DEFAULT 0,

-- ----------------------------------------------------------------------
-- Test groups are sometime useful for analysis of coverage data.
-- one row per test group, per testrun
CREATE TABLE IF NOT EXISTS  test_groups (
    testrun_id INT,
    id INT,
    name TEXT,
    PRIMARY KEY(testrun_id, id),
    FOREIGN KEY(testrun_id) REFERENCES testruns(id) ON DELETE CASCADE
) ENGINE=INNODB;

