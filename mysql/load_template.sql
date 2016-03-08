
-- mysql -u smartuser -p -P 3520 -h esekilx0007-sql8.rnd.ki.sw.ericsson.se < load_mysql.sql
/*
Limitation:  LOAD DATA INFILE @variable is not supported (https://bugs.mysql.com/bug.php?id=39115)
Workaround: replace with sed prior to calling the SQL script:
cat /home/eseprud/share/smarttest/gcov2covDB/mysql/load_template.sql | sed s/_TEST_RESULTS_ID_/$TEST_RESULTS_ID/g | sed s/_TEST_POSITION_/$POSITION/g | sed s/_GIT_COMMIT_/`git --git-dir $WORKSPACE/radiosw/.git rev-parse HEAD`/g |  sed s/_TEST_FRAMEWORK_/mira/g |  sed s/_TEST_SUITE_/$TEST_SUITE/g | sed s/_FILE_PATH_/$PWD/g > load_mysql_now.sql

mysql -u smartuser -ppassword -P 3520 -h esekilx0007-sql8.rnd.ki.sw.ericsson.se < load_mysql_now.sql

*/

-- set the following when loading script as described on previous line.
SET @test_results_id=_TEST_RESULTS_ID_;
SET @testposition=_TEST_POSITION_;
SET @git_commit='_GIT_COMMIT_';
SET @framework='_TEST_FRAMEWORK_';
SET @testsuite='_TEST_SUITE_';

USE smarttestdb;

INSERT INTO testruns (time_added_epoch, testposition, test_results_id, git_commit, framework, testsuite)
VALUES ( unix_timestamp(now()), @testposition, @test_results_id, @git_commit, @framework, @testsuite);

-- get the id of the newly inserted testruns row:
SELECT id, @testrun_id:=id FROM testruns ORDER BY id DESC LIMIT 1;

-- keep only the most recent builds unless they were tagged to never be deleted.
-- DELETE FROM testruns WHERE id < (@testrun_id - 100) and never_delete=0;

-- ----------------------------------------------------------------------
LOAD DATA LOCAL INFILE '_FILE_PATH_/tests.csv'
INTO TABLE tests
COLUMNS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES -- ignore header
(id, test_group_id, mangled_name, name, path, execution_time_secs, passed, failed )
SET testrun_id = @testrun_id
;

-- ----------------------------------------------------------------------
LOAD DATA LOCAL INFILE '_FILE_PATH_/source_files.csv'
INTO TABLE source_files
COLUMNS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES -- ignore header
(id, name)
SET testrun_id = @testrun_id
;

-- ----------------------------------------------------------------------
LOAD DATA LOCAL INFILE '_FILE_PATH_/functions.csv'
INTO TABLE functions
COLUMNS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES -- ignore header
(id,source_file_id,source_line,mangled_name,name)
SET testrun_id = @testrun_id
;

-- ----------------------------------------------------------------------
LOAD DATA LOCAL INFILE '_FILE_PATH_/funccov.csv'
IGNORE -- ignore load errors caused by duplicate keys. Some odd symbols do cause this e.g. __tcf_0
INTO TABLE funccov
COLUMNS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES -- ignore header
(test_id,function_id,visited)
SET testrun_id = @testrun_id
;

-- ----------------------------------------------------------------------
LOAD DATA LOCAL INFILE '_FILE_PATH_/test_groups.csv'
INTO TABLE test_groups
COLUMNS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES -- ignore header
(id, name)
SET testrun_id = @testrun_id
;
