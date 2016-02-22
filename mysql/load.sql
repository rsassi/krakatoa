-- this file is only for testing. Use load_template.sql to generate the production version of load.sql


SET @testposition=139;
SET @test_results_id=1234;
SET @git_commit='deadbeef';
SET @framework='mira';
SET @filepath='c:/data/';
SET @testsuite='debug';

USE smarttestdb;


-- TODO: lock insert and select and delete in a transaction
INSERT INTO testruns (time_added_epoch, testposition, test_results_id, git_commit, framework, testsuite)
VALUES ( unix_timestamp(now()), @testposition, @test_results_id, @git_commit, @framework, @testsuite);

-- get the id of the newly inserted testruns row:
SELECT id, @testrun_id:=id FROM testruns ORDER BY id DESC LIMIT 1;

-- keep only the last 30 builds
-- DELETE FROM testruns WHERE id< @testrun_id-30;

-- ----------------------------------------------------------------------
LOAD DATA LOCAL INFILE 'c:/data/tests.csv'
INTO TABLE tests
COLUMNS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '@' -- little hack to handle "\" delimiters in file paths
LINES TERMINATED BY '\n'
IGNORE 1 LINES -- ignore header
(id, mangled_name, name, path)
SET testrun_id = @testrun_id
;

-- ----------------------------------------------------------------------
LOAD DATA LOCAL INFILE 'c:/data/source_files.csv'
INTO TABLE source_files
COLUMNS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '@' -- little hack to handle "\" delimiters in file paths
LINES TERMINATED BY '\n'
IGNORE 1 LINES -- ignore header
(id, name)
SET testrun_id = @testrun_id
;

-- ----------------------------------------------------------------------
LOAD DATA LOCAL INFILE 'c:/data/functions.csv'
INTO TABLE functions
COLUMNS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '@' -- little hack to handle "\" delimiters in file paths
LINES TERMINATED BY '\n'
IGNORE 1 LINES -- ignore header
(id,source_file_id,source_line,mangled_name,name)
SET testrun_id = @testrun_id
;

-- ----------------------------------------------------------------------
LOAD DATA LOCAL INFILE 'c:/data/funccov.csv'
IGNORE -- ignore errors for now as there are duplicates: eg. __tcf_0
INTO TABLE funccov
COLUMNS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '@' -- little hack to handle "\" delimiters in file paths
LINES TERMINATED BY '\n'
IGNORE 1 LINES -- ignore header
(test_id,function_id,visited)
SET testrun_id = @testrun_id
;
